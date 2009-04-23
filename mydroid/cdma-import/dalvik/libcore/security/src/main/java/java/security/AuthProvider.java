/*
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

/**
* @author Boris V. Kuznetsov
* @version $Revision$
*/

package java.security;

import javax.security.auth.Subject;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.login.LoginException;

/**
 * @com.intel.drl.spec_ref
 * 
 */

public abstract class AuthProvider extends Provider {

    /**
     * @serial
     */
    private static final long serialVersionUID = 4197859053084546461L;

    /**
     * @com.intel.drl.spec_ref
     * 
     */
    protected AuthProvider(String name, double version, String info) {
        super(name, version, info); 
    }
    
    /**
     * @com.intel.drl.spec_ref
     * 
     */
    public abstract void login(Subject subject, CallbackHandler handler) throws LoginException;
    
    /**
     * @com.intel.drl.spec_ref
     * 
     */
    public abstract void logout() throws LoginException;
    
    /**
     * @com.intel.drl.spec_ref
     * 
     */
    public abstract void setCallbackHandler(CallbackHandler handler);
}