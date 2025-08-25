# Herramientas y Extensiones para Diagramas

## Extensiones de VS Code Recomendadas

### 1. **Mermaid Preview**
- **ID**: `bierner.markdown-mermaid`
- **Descripción**: Previsualiza diagramas Mermaid en archivos Markdown
- **Uso**: Abre archivos `.md` con diagramas Mermaid y ve la previsualización

### 2. **Mermaid Diagram Viewer**
- **ID**: `tomoyukim.vscode-mermaid-preview`
- **Descripción**: Herramienta alternativa para visualizar diagramas Mermaid
- **Características**: Exporta a PNG, SVG, PDF

### 3. **PlantUML**
- **ID**: `jebbs.plantuml`
- **Descripción**: Soporte para diagramas PlantUML
- **Uso**: Para diagramas de clases, secuencia, casos de uso

### 4. **Draw.io Integration**
- **ID**: `hediet.vscode-drawio`
- **Descripción**: Editor de diagramas integrado en VS Code
- **Características**: Diagramas de flujo, arquitectura, UML

### 5. **Markdown All in One**
- **ID**: `yzhang.markdown-all-in-one`
- **Descripción**: Mejora la experiencia con Markdown
- **Características**: Previsualización, atajos, formateo

## Herramientas Online

### 1. **Mermaid Live Editor**
- **URL**: https://mermaid.live/
- **Uso**: Crear y editar diagramas Mermaid online
- **Características**: Exporta a PNG, SVG, PDF

### 2. **Draw.io (diagrams.net)**
- **URL**: https://app.diagrams.net/
- **Uso**: Diagramas profesionales
- **Características**: Plantillas, colaboración, integración con Google Drive

### 3. **Lucidchart**
- **URL**: https://www.lucidchart.com/
- **Uso**: Diagramas empresariales
- **Características**: Colaboración en tiempo real, integración con herramientas

### 4. **Figma**
- **URL**: https://www.figma.com/
- **Uso**: Diseño de UI/UX y diagramas
- **Características**: Prototipado, colaboración

## Herramientas Específicas para Flutter

### 1. **Flutter Inspector**
- **Uso**: Analizar la estructura de widgets en tiempo real
- **Comando**: `flutter inspector`
- **Características**: Árbol de widgets, propiedades, debugging

### 2. **Flutter Performance**
- **Uso**: Analizar rendimiento de la aplicación
- **Comando**: `flutter run --profile`
- **Características**: Timeline, memoria, CPU

### 3. **Flutter Doctor**
- **Uso**: Diagnóstico del entorno de desarrollo
- **Comando**: `flutter doctor`
- **Características**: Verificar dependencias, configuración

## Generadores de Código

### 1. **Flutter Architecture Generator**
```bash
# Instalar
dart pub global activate flutter_architecture_generator

# Usar
flutter_architecture_generator generate
```

### 2. **Flutter Code Generator**
```yaml
# pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.7
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
```

### 3. **Riverpod Code Generator**
```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3

dev_dependencies:
  riverpod_generator: ^2.3.9
  build_runner: ^2.4.7
```

## Scripts Útiles

### 1. **Generador de Diagramas de Clases**
```python
# generate_class_diagram.py
import os
import re

def generate_class_diagram(dart_files):
    mermaid_code = "classDiagram\n"
    
    for file in dart_files:
        with open(file, 'r') as f:
            content = f.read()
            classes = re.findall(r'class\s+(\w+)', content)
            for class_name in classes:
                mermaid_code += f"    class {class_name}\n"
    
    return mermaid_code

# Uso
dart_files = ['lib/datos/modelos/usuario.dart', 'lib/negocio/providers/auth_provider.dart']
diagram = generate_class_diagram(dart_files)
print(diagram)
```

### 2. **Analizador de Dependencias**
```bash
#!/bin/bash
# analyze_dependencies.sh

echo "Analizando dependencias del proyecto..."

# Generar diagrama de dependencias
flutter pub deps --style=tree > dependencies.txt

# Crear diagrama Mermaid
cat > dependency_diagram.md << EOF
# Diagrama de Dependencias

\`\`\`mermaid
graph TD
$(cat dependencies.txt | sed 's/├── /    A --> B/g' | sed 's/└── /    A --> C/g')
\`\`\`
EOF

echo "Diagrama generado en dependency_diagram.md"
```

### 3. **Generador de Documentación**
```dart
// lib/tools/doc_generator.dart
import 'dart:io';

class DocGenerator {
  static void generateArchitectureDoc() {
    final content = '''
# Arquitectura del Proyecto

## Estructura de Carpetas
\`\`\`
lib/
├── datos/
│   ├── modelos/
│   └── servicios/
├── negocio/
│   └── providers/
└── presentacion/
    └── pantallas/
\`\`\`

## Diagrama de Componentes
\`\`\`mermaid
graph TB
    A[Presentación] --> B[Negocio]
    B --> C[Datos]
    C --> D[Almacenamiento]
\`\`\`
''';

    File('ARCHITECTURE.md').writeAsStringSync(content);
  }
}
```

## Configuración de VS Code

### 1. **settings.json**
```json
{
  "markdown.preview.breaks": true,
  "markdown.preview.fontSize": 14,
  "mermaid.theme": "default",
  "plantuml.server": "https://www.plantuml.com/plantuml",
  "drawio.diagrams.net.theme": "kennedy"
}
```

### 2. **tasks.json**
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Generate Architecture Docs",
      "type": "shell",
      "command": "dart",
      "args": ["run", "lib/tools/doc_generator.dart"],
      "group": "build"
    },
    {
      "label": "Analyze Dependencies",
      "type": "shell",
      "command": "./analyze_dependencies.sh",
      "group": "test"
    }
  ]
}
```

## Mejores Prácticas

### 1. **Organización de Diagramas**
```
docs/
├── diagrams/
│   ├── architecture/
│   ├── sequence/
│   └── flow/
├── README.md
└── ARCHITECTURE.md
```

### 2. **Convenciones de Nomenclatura**
- **Diagramas de secuencia**: `sequence_login.md`
- **Diagramas de arquitectura**: `architecture_overview.md`
- **Diagramas de flujo**: `flow_authentication.md`

### 3. **Versionado**
- Incluir diagramas en el control de versiones
- Actualizar diagramas cuando cambie la arquitectura
- Usar comentarios para explicar decisiones de diseño

### 4. **Documentación Automática**
```yaml
# .github/workflows/docs.yml
name: Generate Documentation

on:
  push:
    branches: [main]
    paths: ['lib/**']

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart run lib/tools/doc_generator.dart
      - run: git add docs/
      - run: git commit -m "Update documentation"
      - run: git push
```

## Recursos Adicionales

### 1. **Documentación Oficial**
- [Mermaid Documentation](https://mermaid-js.github.io/mermaid/)
- [PlantUML Documentation](https://plantuml.com/)
- [Draw.io Documentation](https://drawio-app.com/docs/)

### 2. **Tutoriales**
- [Flutter Architecture Patterns](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/about_hooks)

### 3. **Comunidad**
- [Flutter Community](https://flutter.dev/community)
- [Mermaid Community](https://github.com/mermaid-js/mermaid)

## Comandos Útiles

```bash
# Generar documentación
flutter pub run build_runner build

# Analizar código
flutter analyze

# Generar diagramas de dependencias
flutter pub deps --style=tree

# Ejecutar tests
flutter test

# Generar documentación de API
dart doc
```

Estas herramientas te ayudarán a crear, mantener y visualizar diagramas de manera eficiente en tu proyecto Flutter. 