/* @(#) $Id: ./src/os_integrator/main.c, 2014/05/03 dcid Exp $
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



int main(int argc, char **argv)
{
    int i = 0;
    int c = 0; 
    int test_config = 0;
    int uid = 0;
    int gid = 0;


    /* Highly recommended not to run as root. However, some integrations 
     * may require it. */
    char *dir  = DEFAULTDIR;
    char *user = MAILUSER;
    char *group = GROUPGLOBAL;
    char *cfg = DEFAULTCPATH;


    IntegratorConfig **integrator_config = NULL;


    /* Setting the name */
    OS_SetName(ARGV0);
        

    while((c = getopt(argc, argv, "vdhtu:g:")) != -1){
        switch(c){
            case 'v':
                print_version();
                break;    
            case 'h':
                help(ARGV0);
                break;
            case 'd':
                nowDebug();
                break;
            case 'u':
                if(!optarg)
                    ErrorExit("%s: -u needs an argument",ARGV0);
                user = optarg;
                break;
            case 'g':
                if(!optarg)
                    ErrorExit("%s: -g needs an argument",ARGV0);
                group = optarg;
                break;
            case 't':
                test_config = 1;    
                break;
            default:
                help(ARGV0);
                break;
        }
    }


    /* Starting daemon */
    debug1(STARTED_MSG, ARGV0);


    /* Check if the user/group given are valid */
    uid = Privsep_GetUser(user);
    gid = Privsep_GetGroup(group);
    if((uid < 0)||(gid < 0))
    {
        ErrorExit(USER_ERROR, ARGV0, user, group);
    }


    /* Reading configuration */
    integrator_config = OS_ReadIntegratorConf(test_config, cfg, integrator_config);



    /* Exit here if test config is set */
    if(test_config)
        exit(0);
     

    /* Pid before going into daemon mode. */
    i = getpid();   
        

    /* Going on daemon mode */
    nowDaemon();
    goDaemonLight();


    
    /* Not configured */
    if(!integrator_config || !integrator_config[0])
    {
        verbose("%s: INFO: Remote integrations not configured. "
                "Clean exit.", ARGV0);
        exit(0);
    }



    /* Creating some randoness  */
    #ifdef __OpenBSD__
    srandomdev();
    #else
    srandom( time(0) + getpid()+ i);
    #endif

    random();

    

    /* Privilege separation */	
    if(Privsep_SetGroup(gid) < 0)
        ErrorExit(SETGID_ERROR,ARGV0,group);

    
    /* Changing user */        
    if(Privsep_SetUser(uid) < 0)
        ErrorExit(SETUID_ERROR,ARGV0,user);


    /* Basic start up completed. */
    debug1(PRIVSEP_MSG,ARGV0,dir,user);


    /* Signal manipulation */
    StartSIG(ARGV0);

    
    /* Creating PID files */
    if(CreatePID(ARGV0, getpid()) < 0)
        ErrorExit(PID_ERROR, ARGV0);

    
    /* Start up message */
    verbose(STARTUP_MSG, ARGV0, (int)getpid());
    

    /* the real daemon now */	
    OS_IntegratorD(integrator_config);
    exit(0);
}


/* EOF */
