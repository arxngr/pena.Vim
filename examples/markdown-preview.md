# Markdown preview

Open this file in Neovim. Use **Space mr** to toggle rendering, **Space ms**
for an editor preview split, and **Space mp** to see diagrams in your browser.

## Tasks

- [x] Read Markdown
- [ ] Preview a Mermaid chart

| Feature | In Neovim | Browser preview |
|---|---|---|
| Headings and tables | Yes | Yes |
| Mermaid diagrams | Source code | Rendered diagram |
| Mathematics | Source code | Typeset formula |

## Mermaid flowchart

```mermaid
graph TD
    A[Open solution] --> B[Choose startup project]
    B --> C[Build project]
    C --> D{Build successful?}
    D -->|Yes| E[Start debugger]
    D -->|No| F[Read build output]
```

## Mermaid sequence diagram

```mermaid
sequenceDiagram
    participant User
    participant API
    participant Database
    User->>API: Request data
    API->>Database: Query
    Database-->>API: Results
    API-->>User: Response
```

## C# code

```csharp
Console.WriteLine("Hello from .NET!");
```

## Mathematics

$$E = mc^2$$
