/**
 * Copyright (c) 2016 Rory Hool
 * <p/>
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * <p/>
 * http://www.apache.org/licenses/LICENSE-2.0
 * <p/>
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

package com.roryhool.videoinfoviewer.analytics;

import com.google.android.gms.analytics.HitBuilders;
import com.roryhool.videoinfoviewer.VideoInfoViewerApp;

public class Analytics {

   public static void logEvent( String category, String action ) {
      logEvent( category, action, null, 0 );
   }

   public static void logEvent( String category, String action, String label ) {
      logEvent( category, action, label, 0 );
   }

   public static void logEvent( String category, String action, String label, long value ) {
      VideoInfoViewerApp.getDefaultTracker().send(
              new HitBuilders.EventBuilder()
                      .setCategory( category )
                      .setAction( action )
                      .setLabel( label )
                      .setValue( value )
                      .build() );
   }
}
