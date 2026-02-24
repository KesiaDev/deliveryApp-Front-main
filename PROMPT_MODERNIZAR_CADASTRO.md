# 🎨 PROMPT PARA @codebase: Modernizar UI das Telas de Cadastro

## 📋 OBJETIVO

Modernizar **APENAS a UI visual** das telas de cadastro (Motorista e Cliente) em `lib/cadastro/cadastro_page.dart`, aplicando o **mesmo estilo moderno e limpo** que foi implementado na tela de login (`lib/login/login_page.dart`).

---

## ⚠️ REGRA FUNDAMENTAL: NÃO ALTERAR LÓGICA

### ❌ O QUE VOCÊ **NÃO PODE** FAZER:

- ❌ Modificar, renomear ou remover **nenhum** `TextEditingController`
- ❌ Alterar **nenhuma** função de validação (`_validateLogin`, `_validateSenha`, `_validateNome`, etc.)
- ❌ Modificar a função `_onClickCadastro` ou qualquer lógica de envio
- ❌ Alterar o `CadastroController` ou seus métodos
- ❌ Modificar rotas (`AppRoutes.cadastro`, `AppRoutes.termos`)
- ❌ Alterar navegações (`Navigator.pushNamed`, `Navigator.pushReplacementNamed`)
- ❌ Modificar `_formKey` ou qualquer `GlobalKey`
- ❌ Alterar estados (`_isObscure`, `_isLoadingCep`, `_isLoadingCnpj`, `_tipoDocumento`, etc.)
- ❌ Modificar funções de autopreenchimento (CEP, CNPJ)
- ❌ Alterar upload de documentos ou lógica de arquivos
- ❌ Modificar `setState` ou qualquer gerenciamento de estado
- ❌ Alterar condições (`if (widget.tipoPagina == 1)`, `if (_tipoDocumento == 'CNPJ')`, etc.)
- ❌ Remover ou modificar campos, mesmo que pareçam desnecessários
- ❌ Alterar a estrutura de dados ou modelos

### ✅ O QUE VOCÊ **DEVE** FAZER:

- ✅ Apenas modernizar o **visual** dos widgets
- ✅ Aplicar o mesmo estilo da tela de login modernizada
- ✅ Manter todos os controllers, validações e lógica intactos
- ✅ Substituir apenas decorações, cores, tipografia e espaçamentos

---

## 🎨 REFERÊNCIA VISUAL: Tela de Login Modernizada

A tela de login em `lib/login/login_page.dart` foi modernizada com:

- **Fundo:** Branco sólido (`#FFFFFF`)
- **Campos:** Fundo cinza claro (`#F5F5F5`), bordas arredondadas (radius 12), sem bordas visíveis quando não focado
- **Tipografia:** Google Fonts Poppins
- **Cores:** 
  - Texto primário: `#1A1A1A`
  - Texto secundário: `#757575`
  - Ícones: `#9E9E9E`
  - Botão primário: `#E53935`
- **Espaçamentos:** Modernos e consistentes

**Use essa tela como referência exata para o estilo visual.**

---

## 🎯 ESPECIFICAÇÕES DE MODERNIZAÇÃO

### 1. **Scaffold e Container Principal**

**ANTES:**
```dart
Scaffold(
  body: Container(
    decoration: BoxDecoration(
      gradient: AppGradients.linear,
      color: const Color(0xff7c94b6),
      image: DecorationImage(...),
    ),
    ...
  ),
)
```

**DEPOIS:**
```dart
Scaffold(
  backgroundColor: Colors.white, // #FFFFFF
  body: SafeArea(
    child: SingleChildScrollView(
      child: Form(...),
    ),
  ),
)
```

**Remover completamente:** gradiente, imagem de fundo, Container com decoração complexa.

---

### 2. **Logo**

**ANTES:**
```dart
final logo = Hero(
  tag: 'hero',
  child: CircleAvatar(
    backgroundColor: Colors.transparent,
    radius: 80.0,
    child: Image.asset(
      AppImages.logo,
      height: 450,
      width: 450,
    ),
  ),
);
```

**DEPOIS:**
```dart
final logo = Hero(
  tag: 'hero',
  child: Padding(
    padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
    child: Image.asset(
      AppImages.logo,
      height: 100,
      width: 100,
      isAntiAlias: true,
    ),
  ),
);
```

**Mudanças:** Remover `CircleAvatar`, reduzir tamanho, adicionar padding superior.

---

### 3. **Título "CADASTRO"**

**ANTES:**
```dart
final textAcessar = Center(
  child: Text(
    "CADASTRO",
    style: AppTextStyles.titleBold,
  ),
);
```

**DEPOIS:**
```dart
final textAcessar = Text(
  'Bem-vinda(o) de volta',
  style: GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A1A1A),
    height: 1.2,
  ),
  textAlign: TextAlign.center,
);

final subtitle = Padding(
  padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
  child: Text(
    'Preencha seus dados para criar sua conta',
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF757575),
    ),
    textAlign: TextAlign.center,
  ),
);
```

**Mudanças:** Usar Google Fonts Poppins, cores modernas, adicionar subtítulo.

---

### 4. **Campos de Texto (TextFormField)**

**PADRÃO PARA TODOS OS CAMPOS:**

```dart
TextFormField(
  style: GoogleFonts.poppins(
    color: Color(0xFF1A1A1A),
    fontSize: 16,
  ),
  controller: [CONTROLLER_EXISTENTE], // MANTER O MESMO
  validator: [VALIDATOR_EXISTENTE], // MANTER O MESMO
  decoration: InputDecoration(
    filled: true,
    fillColor: Color(0xFFF5F5F5), // Fundo cinza claro
    hintText: '[PLACEHOLDER]',
    hintStyle: GoogleFonts.poppins(
      color: Color(0xFF9E9E9E),
      fontSize: 16,
    ),
    prefixIcon: Icon([ICONE], color: Color(0xFF9E9E9E)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none, // Sem borda visível
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFE53935), width: 2), // Borda vermelha no foco
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFE53935), width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Color(0xFFE53935), width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),
)
```

**Aplicar este padrão para:**
- `meuEmail` (controller: `_tMeuLogin`)
- `minhaSenha` (controller: `_tMinhaSenha`)
- `confirmarSenha` (controller: `_tConfirmarSenha`)
- `meuNome` (controller: `_tMeuNome`)
- `emailMotoristaAmigo` (controller: `_tEmailMotorista`)
- `cpf` (controller: `_cpf`)
- `desCepText` (controller: `_desCep`)
- `desRuaText` (controller: `_desRua`)
- `desNumeroText` (controller: `_desNumero`)
- `desBairroText` (controller: `_desBairro`)
- `desCidadeText` (controller: `_desCidade`)
- `desEstadoText` (controller: `_desEstado`)
- `desPlacaText` (controller: `_des_placa`)
- `desModeloText` (controller: `_des_modelo`)

**MANTER:** Todos os controllers, validators, inputFormatters, onChanged, etc.

---

### 5. **Seções (_buildSection)**

**ANTES:**
```dart
Widget _buildSection({
  required String title,
  required List<Widget> children,
  IconData? icon,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 20),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}
```

**DEPOIS:**
```dart
Widget _buildSection({
  required String title,
  required List<Widget> children,
  IconData? icon,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Color(0xFF9E9E9E), size: 20),
              SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...children,
      ],
    ),
  );
}
```

**Mudanças:** 
- Remover Container com fundo translúcido
- Usar Google Fonts Poppins
- Cores modernas (texto escuro, ícones cinza)
- Aumentar espaçamento inferior

---

### 6. **Botão ENVIAR**

**ANTES:**
```dart
final enviarButton = Padding(
  padding: EdgeInsets.symmetric(vertical: 16.0),
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.red,
      padding: EdgeInsets.all(25),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.red),
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    onPressed: () => _onClickCadastro(context), // MANTER
    child: const Text('ENVIAR', style: TextStyle(color: Colors.white)),
  ),
);
```

**DEPOIS:**
```dart
final enviarButton = SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFE53935),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    ),
    onPressed: () => _onClickCadastro(context), // MANTER EXATAMENTE
    child: Text(
      'ENVIAR',
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  ),
);
```

**Mudanças:** 
- Altura fixa 48
- Radius 12 (menor)
- Google Fonts Poppins
- Sem elevation
- **MANTER:** `onPressed` exatamente como está

---

### 7. **Botões de Upload de Documentos**

**ANTES:**
```dart
final addCarteiraMotorista = Padding(
  padding: EdgeInsets.symmetric(vertical: 16.0),
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.red,
      padding: EdgeInsets.all(25),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.red),
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    onPressed: () async { ... }, // MANTER
    child: Text('Carteira de motorista: ' + desNomeCarteira, ...),
  ),
);
```

**DEPOIS:**
```dart
final addCarteiraMotorista = SizedBox(
  width: double.infinity,
  height: 48,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: Color(0xFFE53935),
      side: BorderSide(color: Color(0xFFE53935), width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
    ),
    onPressed: () async { ... }, // MANTER EXATAMENTE
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file, color: Color(0xFFE53935), size: 20),
        SizedBox(width: 8),
        Text(
          desNomeCarteira.isEmpty 
            ? 'Anexar CNH' 
            : 'CNH: ${desNomeCarteira}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE53935),
          ),
        ),
      ],
    ),
  ),
);
```

**Aplicar o mesmo padrão para:**
- `addCartaoCnpjMotorista`
- Qualquer outro botão de upload

**MANTER:** Toda a lógica de `onPressed`, `FilePicker`, `setState`, etc.

---

### 8. **Seletor de Tipo de Documento (CPF/CNPJ)**

**MANTER:** A lógica completa do `tipoDocumentoSelector`, apenas modernizar o visual:

```dart
tipoDocumentoSelector = Container(
  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
  decoration: BoxDecoration(
    color: Color(0xFFF5F5F5), // Fundo cinza claro
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Color(0xFFE0E0E0), width: 1),
  ),
  child: Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _tipoDocumento = 'CPF';
              _cpf.clear();
              _cnpjJaConsultado = false;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _tipoDocumento == 'CPF' 
                  ? Color(0xFFE53935) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'CPF',
                style: GoogleFonts.poppins(
                  color: _tipoDocumento == 'CPF' 
                      ? Colors.white 
                      : Color(0xFF1A1A1A),
                  fontWeight: _tipoDocumento == 'CPF' 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _tipoDocumento = 'CNPJ';
              _cpf.clear();
              _cnpjJaConsultado = false;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _tipoDocumento == 'CNPJ' 
                  ? Color(0xFFE53935) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'CNPJ/MEI',
                style: GoogleFonts.poppins(
                  color: _tipoDocumento == 'CNPJ' 
                      ? Colors.white 
                      : Color(0xFF1A1A1A),
                  fontWeight: _tipoDocumento == 'CNPJ' 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
```

**MANTER:** Toda a lógica de `setState`, `_tipoDocumento`, `_cnpjJaConsultado`, etc.

---

### 9. **Ícones de Visualização de Documentos**

**MANTER:** A lógica completa, apenas ajustar a cor:

```dart
final seeIconCarteira = IconButton(
  icon: Icon(
    Icons.visibility_outlined, // ou Icons.visibility_off_outlined
    color: Color(0xFF9E9E9E), // Cinza moderno
  ),
  onPressed: () { ... }, // MANTER EXATAMENTE
);
```

---

### 10. **Indicadores de Loading (CEP, CNPJ)**

**MANTER:** A lógica de loading, apenas modernizar o visual:

```dart
if (_isLoadingCep)
  Padding(
    padding: EdgeInsets.only(left: 8),
    child: SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
      ),
    ),
  ),
```

---

### 11. **Mensagens de Sucesso (✓ arquivo anexado)**

**MANTER:** A lógica, apenas modernizar:

```dart
if (desNomeCarteira.isNotEmpty) ...[
  SizedBox(height: 8),
  Row(
    children: [
      Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
      SizedBox(width: 8),
      Expanded(
        child: Text(
          desNomeCarteira,
          style: GoogleFonts.poppins(
            color: Color(0xFF4CAF50),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      seeIconCarteira,
    ],
  ),
],
```

---

## 📐 ESTRUTURA FINAL DO LAYOUT

```dart
Scaffold(
  backgroundColor: Colors.white,
  body: SafeArea(
    child: SingleChildScrollView(
      child: Form(
        key: _formKey, // MANTER
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              logo,
              textAcessar,
              subtitle,
              SizedBox(height: 32.0),
              // Seção: Conta
              _buildSection(...),
              // Seção: Dados Pessoais
              _buildSection(...),
              // Seção: Endereço
              _buildSection(...),
              // Seção: Documentos
              _buildSection(...),
              SizedBox(height: 24),
              enviarButton,
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ),
  ),
)
```

---

## ✅ CHECKLIST FINAL

Antes de finalizar, verifique:

- [ ] Todos os `TextEditingController` estão intactos
- [ ] Todas as funções de validação estão preservadas
- [ ] `_onClickCadastro` não foi modificado
- [ ] Todas as rotas e navegações estão preservadas
- [ ] Estados (`_isObscure`, `_isLoadingCep`, etc.) estão intactos
- [ ] Lógica de autopreenchimento (CEP, CNPJ) está preservada
- [ ] Upload de documentos funciona igual
- [ ] Condicionais (`if (widget.tipoPagina == 1)`, etc.) estão preservadas
- [ ] Nenhum campo foi removido
- [ ] Visual está moderno e consistente com a tela de login

---

## 🎯 RESULTADO ESPERADO

Após a modernização, as telas de cadastro devem:

- ✅ Ter visual idêntico à tela de login modernizada
- ✅ Manter 100% da funcionalidade existente
- ✅ Ser limpas, modernas e profissionais
- ✅ Usar Google Fonts Poppins
- ✅ Ter fundo branco, campos cinza claro, botões vermelhos
- ✅ Manter todas as seções organizadas
- ✅ Funcionar exatamente como antes, apenas mais bonito

---

**FIM DO PROMPT**





