/* @(#) $Id: ./src/os_integrator/integrator.h, 2014/05/03 dcid Exp $
 */


#ifndef _INTEGRATORD_H
#define _INTEGRATORD_H


#include "config/integrator-config.h"


/** Prototypes **/

/* Read syslog config */
void *OS_ReadIntegratorConf(int test_config, char *cfgfile,
                            IntegratorConfig **integrator_config);




/* Database inserting main function */
void OS_IntegratorD(IntegratorConfig **integrator_config);




#endif
