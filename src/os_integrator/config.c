/* @(#) $Id: ./src/os_integrator/config.c, 2014/05/04 dcid Exp $
 */

/* Copyright (C) 2014 Daniel B. Cid
 * All rights reserved.
 *
 * This program is a free software; you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License (version 2) as published by the FSF - Free Software
 * Foundation.
 *
 */


#include "integrator.h"
#include "config/global-config.h"
#include "config/config.h"


void *OS_ReadIntegratorConf(int test_config, char *cfgfile, 
                            IntegratorConfig **integrator_config)
{
    int modules = 0;
    GeneralConfig gen_config;


    /* Modules for the configuration */
    modules|= CINTEGRATORD;
    gen_config.data = integrator_config;

    
    /* Reading configuration */
    if(ReadConfig(modules, cfgfile, &gen_config, NULL) < 0)
    {
        ErrorExit(CONFIG_ERROR, ARGV0, cfgfile);
        return(NULL);
    }    

    
    integrator_config = gen_config.data;

    return(integrator_config);
}

/* EOF */
