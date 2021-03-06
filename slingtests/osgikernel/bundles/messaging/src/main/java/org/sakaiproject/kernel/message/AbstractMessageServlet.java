/*
 * Licensed to the Sakai Foundation (SF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The SF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
package org.sakaiproject.kernel.message;

import static org.sakaiproject.kernel.api.message.MessageConstants.MESSAGE_OPERATION;

import org.apache.sling.api.SlingHttpServletRequest;
import org.apache.sling.api.SlingHttpServletResponse;
import org.sakaiproject.kernel.resource.AbstractVirtualPathServlet;

import java.io.IOException;

import javax.servlet.ServletException;

/**
 * 
 */
public abstract class AbstractMessageServlet extends AbstractVirtualPathServlet {

  /**
   *
   */
  private static final long serialVersionUID = 7894134023341453341L;


  /**
   * {@inheritDoc}
   * 
   * @see org.sakaiproject.kernel.resource.AbstractVirtualPathServlet#hashRequest(org.apache.sling.api.SlingHttpServletRequest,
   *      org.apache.sling.api.SlingHttpServletResponse)
   */
  @Override
  public void hashRequest(SlingHttpServletRequest request,
      SlingHttpServletResponse response) throws IOException, ServletException {
    String method = request.getMethod();
    if ("GET|HEAD|OPTIONS".indexOf(method) < 0) {
      request.setAttribute(MESSAGE_OPERATION, request.getMethod());
    }
    super.hashRequest(request, response);
  }

}
