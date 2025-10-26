import SwiftUI

struct FeedErrorBanner: View {
    let feedTitle: String
    let errorMessage: String
    let onDismiss: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(feedTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Failed to refresh")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
            
            if isExpanded {
                Divider()
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Details")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color(.systemRed).opacity(0.1))
        .cornerRadius(8)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Feed error: \(feedTitle)")
        .accessibilityHint("Tap to see error details")
    }
}

struct ErrorCountBanner: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) Feed Errors")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("Tap to view details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(.systemRed).opacity(0.1))
            .cornerRadius(8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) feed errors")
        .accessibilityHint("Tap to see all error details")
    }
}

struct FeedErrorDialogView: View {
    let errors: [FeedErrorInfo]
    let onDismissError: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(errors, id: \.feedURL) { errorInfo in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(errorInfo.feedTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                Text(errorInfo.displayMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(nil)
                            }
                            
                            Spacer()
                            
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    onDismissError(errorInfo.feedURL)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Feed Errors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Clear All") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            for error in errors {
                                onDismissError(error.feedURL)
                            }
                        }
                        dismiss()
                    }
                    
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        FeedErrorBanner(
            feedTitle: "The Verge",
            errorMessage: "Network error: The internet connection appears to be offline.",
            onDismiss: {}
        )
        
        FeedErrorBanner(
            feedTitle: "Hacker News",
            errorMessage: "Invalid feed URL",
            onDismiss: {}
        )
        
        ErrorCountBanner(count: 5, onTap: {})
    }
    .padding()
}
