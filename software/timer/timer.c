/*
 * Copyright (C) 2021 ETH Zurich and University of Bologna
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* 
 * Mantainer: Luca Valente (luca.valente2@unibo.it)
 */

#include <stdio.h>
#include <stdint.h>
#include "utils.h"
#include "../common/encoding.h"
#include "udma.h"
#include "timer.h"
#define BUFFER_SIZE 32
//#define VERBOSE
//#define EXTRA_VERBOSE

int main() {
  alsaqr_periph_padframe_periphs_pad_gpio_pwm0_mux_set (1);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm1_mux_set (2);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm2_mux_set (3);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm3_mux_set (4);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm4_mux_set (5);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm5_mux_set (6);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm6_mux_set (7);
  alsaqr_periph_padframe_periphs_pad_gpio_pwm7_mux_set (8);

  enable_timer();
  config_counter(0,0,0,0,0,0);
  set_counter_range(0,0,6);
  set_threshold(0,0,1,1);
  set_threshold(0,1,2,2);
  set_threshold(0,2,3,3);
  set_threshold(0,3,4,3);
  start_timer();
  
  for(volatile int i = 0; i<100; i++)
    asm volatile ("wfi");
  
  return 0;
  
}
