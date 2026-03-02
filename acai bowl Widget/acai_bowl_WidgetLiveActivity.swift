//
//  acai_bowl_WidgetLiveActivity.swift
//  acai bowl Widget
//
//  Created by 서지우 on 3/2/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct acai_bowl_WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct acai_bowl_WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: acai_bowl_WidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension acai_bowl_WidgetAttributes {
    fileprivate static var preview: acai_bowl_WidgetAttributes {
        acai_bowl_WidgetAttributes(name: "World")
    }
}

extension acai_bowl_WidgetAttributes.ContentState {
    fileprivate static var smiley: acai_bowl_WidgetAttributes.ContentState {
        acai_bowl_WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: acai_bowl_WidgetAttributes.ContentState {
         acai_bowl_WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: acai_bowl_WidgetAttributes.preview) {
   acai_bowl_WidgetLiveActivity()
} contentStates: {
    acai_bowl_WidgetAttributes.ContentState.smiley
    acai_bowl_WidgetAttributes.ContentState.starEyes
}
