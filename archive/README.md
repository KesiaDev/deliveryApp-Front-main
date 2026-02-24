# Arquivos Arquivados

Este diretório contém arquivos que foram identificados como não utilizados no projeto e foram movidos para preservação antes da remoção.

## Arquivos Arquivados

### 1. `lib/bussiness/service/dummyImport.dart`
**Data de Arquivamento:** 2025-11-27  
**Motivo:** Arquivo não é referenciado em nenhum lugar do projeto. Contém classes `DummyImport` e `AnchorElement` que nunca são importadas ou utilizadas.

### 2. `lib/bussiness/service/AnchorElement.dart`
**Data de Arquivamento:** 2025-11-27  
**Motivo:** Classe `AnchorElement` não é utilizada. Os arquivos que precisam de `AnchorElement` usam `html.AnchorElement` do pacote `dart:html` ou `package:html`.

### 3. `lib/shared/services/service_locator.dart`
**Data de Arquivamento:** 2025-11-27  
**Motivo:** Arquivo não é referenciado em nenhum lugar do projeto. O `GetIt` locator nunca é inicializado ou utilizado.

### 4. `lib/admin/ValoresTaxas`
**Data de Arquivamento:** 2025-11-27  
**Motivo:** Arquivo duplicado. A classe `ValoresTaxas` já existe em `lib/bussiness/service/admin_service.dart` e é utilizada a partir de lá. Este arquivo sem extensão `.dart` não é importado.

## Nota

Estes arquivos podem ser removidos permanentemente após verificação. Eles foram arquivados para permitir recuperação caso seja necessário.

