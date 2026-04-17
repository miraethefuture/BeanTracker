//
//  QuickLogWidget.swift
//  BeanTrackerApp
//
//  Created by Mirae on 4/17/26.
//  Copyright © 2026 miraethefuture. All rights reserved.
//

import SwiftUI
import WidgetKit

struct QuickLogEntry: TimelineEntry {
    let date: Date
}

struct QuickLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry(date: .now)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
        completion(QuickLogEntry(date: .now))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
        let entry = QuickLogEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct QuickLogWidgetEntryView: View {
    let entry: QuickLogEntry
    
    var body: some View {
        Link(destination: URL(string: "beantracker://brew")!) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.title2)
                
                Text("빠른 기록")
                    .font(.headline)
                
                Text("추출 화면 열기")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding()
        }
    }
}

#Preview {
    let entry: QuickLogEntry = .init(date: .now)
    QuickLogWidgetEntryView(entry: entry)
}

struct QuickLogWidget: Widget {
    let kind = "QuickLogWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogProvider()) { entry in
            QuickLogWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("빠른 기록")
        .description("원두 추출 기록 화면을 바로 엽니다.")
        .supportedFamilies([.systemSmall])
    }
}
