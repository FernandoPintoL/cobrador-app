# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

## [1.0.2] - 2025-01-24

### Corregido
- Corregido overflow en AppBar de la pantalla de créditos cuando los tabs contienen texto largo con contadores
- Corregido overflow en el título del AppBar en la pantalla de detalle de crédito
- Corregido overflow en el header del resumen del crédito cuando el badge de estado y el título son largos
- Corregido overflow en la información del cliente cuando el nombre es muy largo
- Corregido overflow en los campos de fecha (Fecha Inicio, Fecha Vencimiento)
- Corregido overflow en los KPIs (Pagado, Saldo, Mora) cuando los montos son grandes
- Mejorado el manejo de texto largo en todos los cards del resumen del crédito

### Mejorado
- Optimizado el tamaño de fuentes en elementos propensos a overflow para mejor visualización en pantallas pequeñas
- Agregado TextOverflow.ellipsis en todos los textos que pueden ser largos
- Mejorada la distribución de espacio en layouts con Row usando Flexible

## [1.0.1] - 2025-01-XX

### Agregado
- Funcionalidades base de la aplicación
- Gestión de créditos y pagos
- Integración con backend
- Sistema de autenticación por roles
- Mapas y geolocalización

## [1.0.0] - 2025-01-XX

### Agregado
- Versión inicial de la aplicación
- Gestión de clientes
- Gestión de cobradores
- Sistema de cajas
- Reportes básicos
