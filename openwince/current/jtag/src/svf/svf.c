/*
 * $Id$
 *
 * Copyright (C) 2004, Arnim Laeuger
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *
 * Written by Arnim Laeuger <arniml@users.sourceforge.net>, 2004.
 *
 * See "Serial Vector Format Specification", Revision E, 1999
 * ASSET InterTech, Inc.
 * http://www.asset-intertech.com/support/svf.pdf
 *
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <sys/time.h>
#include <math.h>

#include "sysdep.h"

#include <jtag.h>
#include <tap.h>
#include <state.h>

#include <brux/cmd.h>

#include "svf.h"
#include "svf_bison.h"

int yyparse(void);


struct sxr {
    struct ths_params params;
    int    no_tdi;
    int    no_tdo;
};


FILE *yyin, *yyout;

int svf_stop_on_mismatch;

static part_t        *part;
static instruction   *ir;
static data_register *dr;


static struct sxr sir_params,
                  sdr_params;

static int endir,
           enddr;

static int runtest_run_state,
           runtest_end_state;

static int svf_trst_absent;
static int svf_state_executed;

/* protocol issued warnings */
static int issued_sir_tdo;
static int issued_runtest_maxtime;


/*
 * svf_force_reset_state()
 *
 * Puts TAP controller into reset state by clocking 5 times with TMS = 1.
 */
static void
svf_force_reset_state(void)
{
  int i;
  for (i = 1; i <= 5; i++)
    chain_clock(chain, 1, 0);
  tap_state_reset(chain);
}


/*
 * svf_goto_state(state)
 *
 * Moves from any TAP state to the specified state.
 * The state traversal is done according to the SVF specification.
 *   See STATE of the Serial Vector Format Specification
 *
 * Encoding of state is according to the jtag suite's defines.
 *
 * Parameter:
 *   state : new TAP controller state
 */
static void
svf_goto_state(int new_state)
{
  int current_state;

  current_state = tap_state(chain);

  /* handle unknown state */
  if (new_state == Unknown_State)
    new_state = Test_Logic_Reset;

  /* abort if new_state already reached */
  if (current_state == new_state)
    return;

  switch (current_state) {
    case Test_Logic_Reset:
      chain_clock(chain, 0, 0);
      break;

    case Run_Test_Idle:
      chain_clock(chain, 1, 0);
      break;

    case Select_DR_Scan:
    case Select_IR_Scan:
      if (new_state == Test_Logic_Reset ||
          new_state == Run_Test_Idle    ||
          (current_state & TAPSTAT_DR && new_state & TAPSTAT_IR)  ||
          (current_state & TAPSTAT_IR && new_state & TAPSTAT_DR))
        /* progress in select-idle/reset loop */
        chain_clock(chain, 1, 0);
      else
        /* enter DR/IR branch */
        chain_clock(chain, 0, 0);
      break;

    case Capture_DR:
      if (new_state == Shift_DR)
        /* enter Shift_DR state */
        chain_clock(chain, 0, 0);
      else
        /* bypass Shift_DR */
        chain_clock(chain, 1, 0);
      break;

    case Capture_IR:
      if (new_state == Shift_IR)
        /* enter Shift_IR state */
        chain_clock(chain, 0, 0);
      else
        /* bypass Shift_IR */
        chain_clock(chain, 1, 0);
      break;

    case Shift_DR:
    case Shift_IR:
      /* progress to Exit1_DR/IR */
      chain_clock(chain, 1, 0);
      break;

    case Exit1_DR:
      if (new_state == Pause_DR)
        /* enter Pause_DR state */
        chain_clock(chain, 0, 0);
      else
        /* bypass Pause_DR */
        chain_clock(chain, 1, 0);
      break;

    case Exit1_IR:
      if (new_state == Pause_IR)
        /* enter Pause_IR state */
        chain_clock(chain, 0, 0);
      else
        /* bypass Pause_IR */
        chain_clock(chain, 1, 0);
      break;

    case Pause_DR:
    case Pause_IR:
      /* progress to Exit2_DR/IR */
      chain_clock(chain, 1, 0);
      break;

    case Exit2_DR:
      if (new_state == Shift_DR)
        /* enter Shift_DR state */
        chain_clock(chain, 0, 0);
      else
        /* progress to Update_DR */
        chain_clock(chain, 1, 0);
      break;

    case Exit2_IR:
      if (new_state == Shift_IR)
        /* enter Shift_IR state */
        chain_clock(chain, 0, 0);
      else
        /* progress to Update_IR */
        chain_clock(chain, 1, 0);
      break;

    case Update_DR:
    case Update_IR:
      if (new_state == Run_Test_Idle)
        /* enter Run_Test_Idle */
        chain_clock(chain, 0, 0);
      else
        /* progress to Select_DR/IR */
        chain_clock(chain, 1, 0);
      break;

    default:
      svf_force_reset_state();
      break;
  }

  /* continue state changes */
  svf_goto_state(new_state);
}


/*
 * svf_map_state(state)
 *
 * Maps the state encoding of the SVF parser to the
 * state encoding of the jtag suite.
 *
 * Parameter:
 *   state : state encoded by/for SVF parser
 *
 * Return value:
 *   state encoded for jtag tools
 */
static int
svf_map_state(int state)
{
  int jtag_state;

  switch (state) {
    case RESET:
      jtag_state = Test_Logic_Reset;
      break;
    case IDLE:
      jtag_state = Run_Test_Idle;
      break;
    case DRSELECT:
      jtag_state = Select_DR_Scan;
      break;
    case DRCAPTURE:
      jtag_state = Capture_DR;
      break;
    case DRSHIFT:
      jtag_state = Shift_DR;
      break;
    case DREXIT1:
      jtag_state = Exit1_DR;
      break;
    case DRPAUSE:
      jtag_state = Pause_DR;
      break;
    case DREXIT2:
      jtag_state = Exit2_DR;
      break;
    case DRUPDATE:
      jtag_state = Update_DR;
      break;

    case IRSELECT:
      jtag_state = Select_IR_Scan;
      break;
    case IRCAPTURE:
      jtag_state = Capture_IR;
      break;
    case IRSHIFT:
      jtag_state = Shift_IR;
      break;
    case IREXIT1:
      jtag_state = Exit1_IR;
      break;
    case IRPAUSE:
      jtag_state = Pause_IR;
      break;
    case IREXIT2:
      jtag_state = Exit2_IR;
      break;
    case IRUPDATE:
      jtag_state = Update_IR;
      break;

    default:
      jtag_state = Unknown_State;
      break;
  }

  return(jtag_state);
}


/*
 * svf_hex2dec(nibble)
 *
 * Converts a hexadecimal nibble (4 bits) to its decimal value.
 *
 * Parameter:
 *   nibble : hexadecimal character
 *
 * Return value:
 *   decimal value of nibble or 0 if nibble is not a hexadecimal character
 */
static int
svf_hex2dec(char nibble)
{
  int lower;

  if (nibble >= '0' && nibble <= '9')
    return((int)(nibble - '0'));

  lower = tolower((int)nibble);
  if (lower >= 'a' && lower <= 'f')
    return(lower - (int)'a' + 10);

  return(0);
}


/*
 * svf_build_bit_string(hex_string, len)
 *
 * Converts the hexadecimal string hex_string into a string of single bits
 * with len elements (bits).
 * If hex_string contains less nibbles than fit into len bits, the resulting
 * bit string is padded with 0 bits.
 *
 * Note:
 * The memory for the resulting bit string is calloc'ed and must be
 * free'd when the bit string is not used anymore.
 *
 * Example:
 *   hex string : 1a
 *   len        : 16
 *   bit string : 0000000000011010
 *
 * Parameter:
 *   hex_string : hex string to be converted
 *   len        : number of bits in resulting bit string
 *
 * Return value:
 *   pointer to new bit string
 *   NULL upon error
 */
static char *
svf_build_bit_string(char *hex_string, int len)
{
  char *bit_string, *bit_string_pos;
  int   nibble;
  char *hex_string_pos;
  int   hex_string_idx;

  if (!(bit_string = (char *)calloc(len + 1, sizeof(char)))) {
    printf( _("out of memory") );
    return(NULL);
  }

  /* copy reduced hexadecimal string to full bit string */
  hex_string_idx = strlen(hex_string);
  hex_string_pos = &(hex_string[hex_string_idx]);
  nibble         = 3;
  bit_string_pos = &(bit_string[len]);
  do {
    bit_string_pos--;
    if (nibble == 3) {
      nibble = 0;
      hex_string_pos--;
      hex_string_idx--;
    } else
      nibble++;

    *bit_string_pos = svf_hex2dec(hex_string_idx >= 0 ? *hex_string_pos : '0') & (1 << nibble) ? '1' : '0';
  } while (bit_string_pos != bit_string);

  bit_string[len] = '\0';

  return(bit_string);
}


/*
 * svf_copy_hex_to_register(hex_string, reg, len)
 *
 * Copies the contents of the hexadecimal string hex_string into the given
 * tap register.
 *
 * Parameter:
 *   hex_string : hex string to be entered in reg
 *   reg        : tap register to hold the converted hex string
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 */
static int
svf_copy_hex_to_register(char *hex_string, tap_register *reg)
{
  char *bit_string;

  if (!(bit_string = svf_build_bit_string(hex_string, reg->len)))
    return(0);

  register_init(reg, bit_string);

  /* free memory as we do not need the intermediate bit_string anymore */
  free(bit_string);

  return(1);
}


/*
 * svf_compare_tdo(tdo, mask, reg)
 *
 * Compares the captured device output in tap register reg with the expected
 * hex_string tdo (specified in SVF command SDR/SDI.
 *
 * Comparison honours the "care" bits in mask ('1') while matching the contents
 * of reg with tdo.
 *
 * Parameter:
 *   tdo  : reference hex string
 *   mask : hex string for masking tdo
 *   reg  : hex string to be compared vs. tdo
 *
 * Return value:
 *   1 : tdo matches reg at all positions where mask is '1'
 *   0 : tdo and reg do not match or error occured
 */
static int
svf_compare_tdo(char *tdo, char *mask, tap_register *reg, YYLTYPE *loc)
{
  char *tdo_bit, *mask_bit;
  int   pos, mismatch, result = 1;

  if (!(tdo_bit = svf_build_bit_string(tdo, reg->len)))
    return(0);
  if (!(mask_bit = svf_build_bit_string(mask, reg->len))) {
    free(tdo_bit);
    return(0);
  }

  /* retrieve string representation */
  register_get_string(reg);

  mismatch = -1;
  for (pos = 0; pos < reg->len; pos++)
    if ((svf_hex2dec(tdo_bit[pos]) ^ reg->string[pos]) & svf_hex2dec(mask_bit[pos]))
      mismatch = pos;

  if (mismatch >= 0) {
    printf( _("Error %s: mismatch at position %d for TDO\n"), "svf", mismatch);
    if (loc != NULL) {
      printf( " in input file between line %d col %d and line %d col %d\n", 
              loc->first_line+1, 
              loc->first_column+1, 
              loc->last_line+1, 
              loc->last_column+1 );
    }
    if (svf_stop_on_mismatch)
      result = 0;
  }

  free(mask_bit);
  free(tdo_bit);

  return(result);
}


/*
 * svf_remember_param(rem, new)
 *
 * Assigns the contents of the string new to the string rem.
 * By doing so, the responsability to free the memory occupied by new
 * is transferred to the code that handles *rem.
 * Nothing happens when new is NULL. In this case the current value of
 * rem has to be "remembered".
 *
 * Parameter:
 *   rem : hex string pointer pointing to the "remembered" string
 *   new : hex string that has to be rememberd
 *         memory of the string is free'd
 */
static void
svf_remember_param(char **rem, char *new)
{
  if (new) {
    if (*rem)
      free(*rem);

    *rem = new;
  }
}


/*
 * svf_all_care(string, number)
 *
 * Allocates a hex string of given length (number gives number of bits)
 * and sets it to all 'F'.
 * The allocated memory of the string has to be free'd by the caller.
 *
 * Parameter:
 *   string : is updated with the pointer to the allocated hex string
 *   number : number of required bits
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 */
static int
svf_all_care(char **string, double number)
{
  char *ptr;
  int num, result;

  result = 1;

  num = (int)number;
  num = num % 4 == 0 ? num / 4 : num / 4 + 1;

  /* build string with all cares */
  if (!(ptr = (char *)calloc(num + 1, sizeof(char)))) {
    printf( _("out of memory") );
    return(0);
  }
  memset(ptr, 'F', num);
  ptr[num] = '\0';

  svf_remember_param(string, ptr);
  /* responsability for free'ing ptr is now at the code that
     operates on *string */

  return(result);
}


/*
 * svf_add_time(start_time, add_secs, result_time)
 *
 * Adds the given number of seconds to start_time. The reslt is returned
 * in result_time.
 * start_time and result_time are of type timeval which makes it necessary
 * to have a dedicated function for adding a time period to start_time.
 * Fractions of add_sec are converted to microseconds and are added to
 * start_time accordingly.
 *
 * Parameter:
 *   start_time : base time
 *   add_secs   : time to be added to start_time
 *                floating point value with 1.0 = 1 sec
 */
static void
svf_add_time(struct timeval *start_time, double add_secs,
             struct timeval *result_time)
{
  result_time->tv_sec  = start_time->tv_sec + (long)floor(add_secs);
  result_time->tv_usec = start_time->tv_usec +
                         (long)((add_secs - floor(add_secs)) * 1000000.0);

  if (result_time->tv_usec > 1000000) {
    result_time->tv_usec -= 1000000;
    result_time->tv_sec  += 1;
  }
}


/*
 * svf_is_later(check, ref)
 *
 * Compares time check against ref.
 *
 * Return value:
 *   1 : check is later in time than ref
 *   0 : otherwise
 */
static int
svf_is_later(struct timeval *check, struct timeval *ref)
{
  int later = 0;

  if (check->tv_sec <= ref->tv_sec) {
    if (check->tv_sec == ref->tv_sec)
      if (check->tv_usec > ref->tv_usec)
        later = 1;
  } else
    later = 1;

  return(later);
}


/*
 * svf_is_later_than_now(check)
 *
 * Compares time check against the current time (aka now).
 *
 * Return value:
 *   1 : check is later than now
 *   0 : otherwise
 */
static int
svf_is_later_than_now(struct timeval *check)
{
  struct timeval  now;
  struct timezone tz = {0, 0};

  gettimeofday(&now, &tz);

  return(svf_is_later(check, &now));
}


/* ***************************************************************************
 * svf_endxr(ir_dr, state)
 *
 * Register end states for shifting IR and DR.
 *
 * Parameter:
 *   ir_dr : selects ENDIR or ENDDR
 *   state : required end state (SVF parser encoding)
 * ***************************************************************************/
void
svf_endxr(enum generic_irdr_coding ir_dr, int state)
{
  switch (ir_dr) {
    case generic_ir:
      endir = svf_map_state(state);
      break;
    case generic_dr:
      enddr = svf_map_state(state);
      break;
  }
}


/* ***************************************************************************
 * svf_frequency(freq)
 *
 * Implements the FREQUENCY command.
 *
 * Parameter:
 *   freq : frequency in HZ
 * ***************************************************************************/
void
svf_frequency(double freq)
{
  frequency = (uint32_t)freq;
}


/* ***************************************************************************
 * svf_hxr(ir_dr, params)
 *
 * Handles HIR, HDR.
 *
 * Note:
 * Functionality not implemented.
 *
 * Parameter:
 *   ir_dr  : selects HIR or HDR
 *   params : paramter set for TXR, HXR and SXR
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
int
svf_hxr(enum generic_irdr_coding ir_dr, struct ths_params *params)
{
  if (params->number != 0.0)
    printf( _("Warning %s: command %s not implemented\n"), "svf",
            ir_dr == generic_ir ? "HIR" : "HDR");

  return(1);
}


/* ***************************************************************************
 * svf_runtest(params)
 *
 * Implements the RUNTEST command.
 *
 * Parameter:
 *   params : paramter set for RUNTEST
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
int
svf_runtest(struct runtest *params)
{
  int run_count;
  struct timeval  start_time, min_endtime, max_endtime;
  struct timezone tz = {0, 0};

  /* check for restrictions */
  if (params->run_count > 0 && params->run_clk != TCK) {
    printf( _("Error %s: only TCK is supported for RUNTEST.\n"), "svf");
    return(0);
  }
  if (params->max_time > 0.0 && params->max_time < params->min_time) {
    printf( _("Error %s: maximum time must be larger or equal to minimum time.\n"),
            "svf");
    return(0);
  }


  /* update default values for run_state and end_state */
  if (params->run_state != 0) {
    runtest_run_state = svf_map_state(params->run_state);

    if (params->end_state == 0)
      runtest_end_state = svf_map_state(params->run_state);
  }
  if (params->end_state != 0)
    runtest_end_state = svf_map_state(params->end_state);

  run_count = (int)(params->run_count);

  svf_goto_state(runtest_run_state);

  /* init timing */
  if (params->max_time > 0.0)
    if (!issued_runtest_maxtime) {
      printf( _("Warning %s: maximum time for RUNTEST not guaranteed.\n"), "svf");
      printf( _(" This message is only displayed once.\n"));
      issued_runtest_maxtime = 1;
    }
  gettimeofday(&start_time, &tz);
  svf_add_time(&start_time, params->min_time, &min_endtime);
  svf_add_time(&start_time, params->max_time, &max_endtime);

  while (run_count > 0 || svf_is_later_than_now(&min_endtime)) {
    chain_clock(chain, 0, 0);
    run_count--;

    if (svf_is_later(&max_endtime, &start_time))
      if (!svf_is_later_than_now(&max_endtime))
        break;
  }

  svf_goto_state(runtest_end_state);

  return(1);
}


/* ***************************************************************************
 * svf_state(path_states, stable_state)
 *
 * Implements the STATE command.
 *
 * Parameter:
 *   path_states  : states to traverse before reaching stable_state
 *                  (SVF parser encoding)
 *   stable_state : final stable state
 *                  (SVF parser encoding)
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
int
svf_state(struct path_states *path_states, int stable_state)
{
  int i;

  svf_state_executed = 1;

  for (i = 0; i < path_states->num_states; i++)
    svf_goto_state(svf_map_state(path_states->states[i]));

  if (stable_state)
    svf_goto_state(svf_map_state(stable_state));

  return(1);
}


/* ***************************************************************************
 * svf_sxr(ir_dr, params)
 *
 * Implements the SIR and SDR commands.
 *
 * Parameter:
 *   ir_dr  : selects SIR or SDR
 *   params : paramter set for TXR, HXR and SXR
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
int
svf_sxr(enum generic_irdr_coding ir_dr, struct ths_params *params, YYLTYPE *loc)
{
  struct sxr *sxr_params;
  int len, result = 1;

  sxr_params = ir_dr == generic_ir ? &sir_params : &sdr_params;

  /* remember parameters */
  svf_remember_param(&sxr_params->params.tdi, params->tdi);

  sxr_params->params.tdo = params->tdo;   /* tdo is not "remembered" */

  svf_remember_param(&sxr_params->params.mask, params->mask);

  svf_remember_param(&sxr_params->params.smask, params->smask);


  /* handle length change for MASK and SMASK */
  if (sxr_params->params.number != params->number) {
    sxr_params->no_tdi = 1;
    sxr_params->no_tdo = 1;

    if (!params->mask)
      if (!svf_all_care(&sxr_params->params.mask, params->number))
        result = 0;
    if (!params->smask)
      if (!svf_all_care(&sxr_params->params.smask, params->number))
        result = 0;
  }

  sxr_params->params.number = params->number;

  /* check consistency */
  if (sxr_params->no_tdi) {
    if (!params->tdi) {
      printf( _("Error %s: first %s command after length change must have a TDI value.\n"), "svf",
              ir_dr == generic_ir ? "SIR" : "SDR");
      result = 0;
    }
    sxr_params->no_tdi = 0;
  }

  /* result of consistency check */
  if (!result)
    return(0);

  /* take over responsability for free'ing parameter strings */
  params->tdi   = NULL;
  params->mask  = NULL;
  params->smask = NULL;


  /*
   * handle tap registers
   */
  len = (int)sxr_params->params.number;
  switch (ir_dr) {
    case generic_ir:
      /* is SIR large enough? */
      if (ir->value->len != len) {
        printf( _("Error %s: SIR command length inconsistent.\n"),
                "svf");
        if (loc != NULL) {
          printf( " in input file between line %d col %d and line %d col %d\n", 
          loc->first_line+1, 
          loc->first_column+1, 
          loc->last_line+1, 
          loc->last_column+1 );
        }
        return(0);
      }
      break;

    case generic_dr:
      /* check data register SDR */
      if (dr->in->len != len) {
        /* length does not match, so install proper registers */
        register_free(dr->in);
        dr->in = NULL;
        register_free(dr->out);
        dr->out = NULL;

        if (!(dr->in = register_alloc(len))) {
          printf( _("out of memory") );
          return(0);
        }
        if (!(dr->out = register_alloc(len))) {
          printf( _("out of memory") );
          return(0);
        }
      }
      break;

  }

  /* fill register with value of TDI parameter */
  if (!svf_copy_hex_to_register(sxr_params->params.tdi,
                                ir_dr == generic_ir ? ir->value :
                                                      dr->in))
    return(0);


  /* shift selected instruction/register */
  switch (ir_dr) {
    case generic_ir:
      svf_goto_state(Shift_IR);
      chain_shift_instructions_mode(chain, 0, EXITMODE_EXIT1);
      svf_goto_state(endir);

      if (sxr_params->params.tdo)
        if (!issued_sir_tdo) {
          printf( _("Warning %s: checking of TDO not supported for SIR.\n"), "svf");
          printf( _(" This message is only displayed once.\n"));
          issued_sir_tdo = 1;
        }
      break;

    case generic_dr:
      svf_goto_state(Shift_DR);
      chain_shift_data_registers_mode(chain, 1, 0, EXITMODE_EXIT1);
      svf_goto_state(enddr);

      if (sxr_params->params.tdo)
        result = svf_compare_tdo(sxr_params->params.tdo, sxr_params->params.mask, dr->out, loc);
      break;
  }

  return(result);
}



/* ***************************************************************************
 * svf_trst(int trst_mode)
 *
 * Sets TRST pin according to trst_mode.
 * TRST modes are encoded via defines in svf.h.
 *
 * Note:
 * The modes Z and ABSENT are not supported.
 *
 * Parameter:
 *   trst_mode : selected mode for TRST
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
int
svf_trst(int trst_mode)
{
  int  trst_cable = -1;
  char *unimplemented_mode;

  if (svf_trst_absent) {
    printf( _("Error %s: no further TRST command allowed after mode ABSENT\n"),
            "svf");
    return(0);
  }

  switch (trst_mode) {
    case ON:
      trst_cable = 0;
      break;
    case OFF:
      trst_cable = 1;
      break;
    case Z:
      unimplemented_mode = "Z";
      break;
    case ABSENT:
      unimplemented_mode = "ABSENT";
      svf_trst_absent = 1;

      if (svf_state_executed) {
        printf( _("Error %s: TRST ABSENT must not be issued after a STATE command\n"),
                "svf");
        return(0);
      }
      if (sir_params.params.number > 0.0 ||
          sdr_params.params.number > 0.0) {
        printf( _("Error %s: TRST ABSENT must not be issued after an SIR or SDR command\n"),
                "svf");
      }
      break;
    default:
      unimplemented_mode = "UNKNOWN";
      break;
  }

  if (trst_cable < 0)
    printf( _("Warning %s: unimplemented mode '%s' for TRST\n"), "svf",
            unimplemented_mode);
  else
    cable_set_trst(chain->cable, trst_cable);

  return(1);
}


/* ***************************************************************************
 * svf_txr(ir_dr, params)
 *
 * Handles TIR, TDR.
 *
 * Note:
 * Functionality not implemented.
 *
 * Parameter:
 *   ir_dr  : selects TIR or TDR
 *   params : paramter set for TXR, HXR and SXR
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
int
svf_txr(enum generic_irdr_coding ir_dr, struct ths_params *params)
{
  if (params->number != 0.0)
    printf( _("Warning %s: command %s not implemented\n"), "svf",
            ir_dr == generic_ir ? "TIR" : "TDR");

  return(1);
}


/* ***************************************************************************
 * svf_run(SVF_FILE, stop_on_mismatch)
 *
 * Main entry point for the 'svf' command. Calls the svf parser.
 *
 * Checks the jtag-environment (availability of SIR instruction and SDR
 * register). Initializes all svf-global variables and performs clean-up
 * afterwards.
 *
 * Parameter:
 *   SVF_FILE         : file handle of SVF file
 *   stop_on_mismatch : 1 = stop upon tdo mismatch
 *                      0 = continue upon mismatch
 *
 * Return value:
 *   1 : all ok
 *   0 : error occured
 * ***************************************************************************/
void
svf_run(FILE *SVF_FILE, int stop_on_mismatch)
{
  const struct sxr sxr_default = { {0.0, NULL, NULL, NULL, NULL},
                                   1, 1};

  /* initialize
     - part
     - instruction register
     - data register */
  if (chain == NULL) {
    printf( _("Error %s: no JTAG chain available\n"), "svf");
    return;
  }
  if (chain->parts == NULL) {
    printf( _("Error %s: chain without any parts\n"), "svf");
    return;
  }
  part = chain->parts->parts[chain->active_part];

  /* setup register SDR if not already existing */
  if (!(dr = part_find_data_register(part, "SDR"))) {
    char *register_cmd[] = {"register",
                            "SDR",
                            "32",
                            NULL};

    if (cmd_run(register_cmd) < 1)
      return;

    if (!(dr = part_find_data_register(part, "SDR"))) {
      printf( _("Error %s: could not establish SDR register\n"), "svf");
      return;
    }
  }

  /* setup instruction SIR if not already existing */
  if (!(ir = part_find_instruction(part, "SIR"))) {
    char *instruction_cmd[] = {"instruction",
                               "SIR",
                               "",
                               "SDR",
                               NULL};
    char *instruction_string;
    int   len, result;

    len = part->instruction_length;
    if (len > 0) {
      if ((instruction_string = (char *)calloc(len+1, sizeof(char))) != NULL) {
        memset(instruction_string, '1', len);
        instruction_string[len] = '\0';
        instruction_cmd[2] = instruction_string;

        result = cmd_run(instruction_cmd);

        free(instruction_string);

        if (result < 1)
          return;
      }
    }

    if (!(ir = part_find_instruction(part, "SIR"))) {
      printf( _("Error %s: could not establish SIR instruction\n"), "svf");
      return;
    }
  }

  /* initialize variables for new parser run */
  svf_stop_on_mismatch = stop_on_mismatch;

  sir_params = sdr_params = sxr_default;

  endir = enddr = Run_Test_Idle;

  runtest_run_state = runtest_end_state = Run_Test_Idle;

  svf_trst_absent    = 0;
  svf_state_executed = 0;

  /* set back flags for issued warnings */
  issued_sir_tdo         = 0;
  issued_runtest_maxtime = 0;


  /* select SIR instruction */
  part_set_instruction(part, "SIR");

  yyin = SVF_FILE;
  yyparse();

  /* clean up */
  /* SIR */
  if (sir_params.params.tdi)
    free(sir_params.params.tdi);
  if (sir_params.params.mask)
    free(sir_params.params.mask);
  if (sir_params.params.smask)
    free(sir_params.params.smask);
  /* SDR */
  if (sdr_params.params.tdi)
    free(sdr_params.params.tdi);
  if (sdr_params.params.mask)
    free(sdr_params.params.mask);
  if (sdr_params.params.smask)
    free(sdr_params.params.smask);
}
