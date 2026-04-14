import ProjectDescription

let workspace = Workspace(
    name: "BeanTracker",
    projects: [
        "Projects/**"
    ],
    additionalFiles: [
        "README.md",
        "docs/**",
        "wiki/**"
    ]
)
