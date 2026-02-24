# 🔧 Implementação de Exclusão de Empresas na API

## 📋 Situação Atual

O frontend está tentando excluir empresas permanentemente, mas a API não possui um endpoint de exclusão implementado. O código tenta múltiplos endpoints possíveis, mas todos retornam erro 404 (não encontrado).

## ✅ O que foi implementado no Frontend

O código já tenta os seguintes endpoints (em ordem de prioridade):

### Endpoints DELETE:
- `DELETE /private/user/{codUsuario}`
- `DELETE /private/user/delete/{codUsuario}`
- `DELETE /private/user/remove/{codUsuario}`
- `DELETE /private/user/excluir/{codUsuario}`
- `DELETE /private/empresa/{codEmpresa}`
- `DELETE /private/empresa/delete/{codEmpresa}`
- `DELETE /private/empresa/remove/{codEmpresa}`
- `DELETE /private/empresa/excluir/{codEmpresa}`

### Endpoints POST (fallback):
- `POST /private/user/delete/{codUsuario}`
- `POST /private/user/remove/{codUsuario}`
- `POST /private/user/excluir/{codUsuario}`
- `POST /private/empresa/delete/{codEmpresa}`
- `POST /private/empresa/remove/{codEmpresa}`
- `POST /private/empresa/excluir/{codEmpresa}`

## 🎯 O que precisa ser implementado no Backend

### Opção 1: Exclusão Física (Recomendado)

Implementar um endpoint DELETE que remove permanentemente a empresa do banco de dados:

```java
// Exemplo em Java/Spring Boot
@DeleteMapping("/private/user/{codUsuario}")
public ResponseEntity<?> excluirUsuario(@PathVariable Integer codUsuario) {
    // Verificar se o usuário é admin
    // Verificar se a empresa existe
    // Verificar se há dados relacionados (corridas, etc.)
    // Se houver dados relacionados, decidir:
    //   - Excluir em cascata
    //   - Ou retornar erro informando que não pode excluir
    
    usuarioService.excluirUsuario(codUsuario);
    return ResponseEntity.ok().build();
}

@DeleteMapping("/private/empresa/{codEmpresa}")
public ResponseEntity<?> excluirEmpresa(@PathVariable Integer codEmpresa) {
    // Similar ao acima
    empresaService.excluirEmpresa(codEmpresa);
    return ResponseEntity.ok().build();
}
```

### Opção 2: Exclusão Lógica

Se não quiser excluir fisicamente, implementar exclusão lógica usando um campo `indExcluido` ou `indAtivo`:

```java
@PostMapping("/private/user/delete/{codUsuario}")
public ResponseEntity<?> excluirUsuarioLogico(@PathVariable Integer codUsuario) {
    Usuario usuario = usuarioService.findById(codUsuario);
    usuario.setIndExcluido(1); // ou indAtivo = 0
    usuarioService.save(usuario);
    return ResponseEntity.ok().build();
}
```

**Nota:** Se usar exclusão lógica, também é necessário:
- Filtrar empresas excluídas na listagem (`/private/empresa/get`)
- Não permitir login de empresas excluídas

## 📝 Endpoints Sugeridos

### Prioridade 1 (Recomendado):
```
DELETE /private/user/{codUsuario}
DELETE /private/empresa/{codEmpresa}
```

### Prioridade 2 (Alternativa):
```
POST /private/user/delete/{codUsuario}
POST /private/empresa/delete/{codEmpresa}
```

## 🔒 Segurança

- Verificar se o usuário logado é ADMIN (`indTipo == 99`)
- Verificar permissões de exclusão
- Validar se a empresa existe antes de excluir
- Considerar exclusão em cascata ou impedir exclusão se houver dados relacionados

## 📊 Resposta Esperada

### Sucesso:
- Status: `200 OK` ou `204 No Content`
- Body: Vazio ou mensagem de sucesso

### Erro:
- Status: `404 Not Found` (empresa não encontrada)
- Status: `403 Forbidden` (sem permissão)
- Status: `400 Bad Request` (dados relacionados impedem exclusão)
- Body: Mensagem de erro explicativa

## 🧪 Teste

Após implementar, testar:

1. Excluir uma empresa sem dados relacionados → Deve funcionar
2. Excluir uma empresa com corridas → Decidir comportamento (cascata ou erro)
3. Tentar excluir como usuário não-admin → Deve retornar 403
4. Tentar excluir empresa inexistente → Deve retornar 404

## 📍 Arquivos do Frontend

- `lib/bussiness/repository/admin_repository.dart` - Método `excluirEmpresa()`
- `lib/admin/admin_empresas_page.dart` - UI de exclusão

---

**Status:** ⏳ Aguardando implementação no backend


