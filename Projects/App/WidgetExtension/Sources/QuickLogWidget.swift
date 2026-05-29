//
//  QuickLogWidget.swift
//  BeanTrackerApp
//
//  Created by Mirae on 4/17/26.
//  Copyright © 2026 miraethefuture. All rights reserved.
//

import SwiftUI
import WidgetKit

private let brewDeepLinkURL = URL(string: "beantracker://brew")

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
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)
                .foregroundStyle(QuickLogWidgetStyle.caramel)

            Text("빠른 기록")
                .font(.headline)
                .foregroundStyle(QuickLogWidgetStyle.espresso)

            Text("추출 화면 열기")
                .font(.caption)
                .foregroundStyle(QuickLogWidgetStyle.olive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .containerBackground(for: .widget) {
            QuickLogWidgetStyle.background
        }
        .widgetURL(brewDeepLinkURL)
    }
}

struct QuickLogWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        QuickLogWidgetEntryView(entry: .init(date: .now))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
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

private enum QuickLogWidgetStyle {
    static let espresso = Color(red: 0.212, green: 0.145, blue: 0.106)
    static let caramel = Color(red: 0.761, green: 0.498, blue: 0.361)
    static let background = Color(red: 0.988, green: 0.98, blue: 0.973)
    static let olive = Color(red: 0.451, green: 0.498, blue: 0.416)
}
