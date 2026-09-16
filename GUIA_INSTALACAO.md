# Guia de instalação do EcoScan AI

## 1. Entenda as duas pastas

A pasta recebida nesta entrega é o **projeto do aplicativo**. A pasta que você já tinha em `Desktop\Flutter App\flutter` é o **Flutter SDK**, a ferramenta usada para abrir e compilar o projeto. Não coloque os arquivos do aplicativo dentro da pasta do SDK.

Recomenda-se manter assim:

```text
C:\src\flutter\                  Flutter SDK
C:\Projetos\EcoScan-Flutter\    este aplicativo
```

Evitar espaços no caminho do Flutter previne erros de ferramentas nativas no Windows. Se quiser manter o SDK onde já está, o caminho curto equivalente costuma ser `C:\Users\SCOREE~1\Desktop\FLUTTE~1\flutter`.

## 2. Preparar o Windows para Android

1. Instale o Android Studio.
2. Na primeira abertura, instale o Android SDK.
3. Em **SDK Manager**, confirme estes componentes:
   - Android SDK Platform 36;
   - Android SDK Build-Tools;
   - Android SDK Command-line Tools;
   - Android Emulator, caso queira usar um celular virtual.
4. Adicione `C:\src\flutter\bin` à variável `Path` do Windows. Se não mover o SDK, use o caminho da sua pasta Flutter.
5. Feche e abra novamente o PowerShell.
6. Execute:

```powershell
flutter doctor
flutter doctor --android-licenses
```

Aceite as licenças com `y`. O item **Android toolchain** precisa aparecer com um sinal verde.

### Se o comando `flutter` não for encontrado

Use temporariamente o caminho completo:

```powershell
& "C:\Users\Score Educacional\Desktop\Flutter App\flutter\bin\flutter.bat" doctor
```

## 3. Abrir o projeto

1. Extraia o ZIP desta entrega.
2. No Android Studio, escolha **Open**.
3. Selecione a pasta `EcoScan-Flutter`, onde está o arquivo `pubspec.yaml`.
4. Abra o terminal nessa pasta e execute:

```powershell
flutter pub get
flutter analyze
flutter test
```

Na primeira vez, o download das bibliotecas pode demorar alguns minutos.

## 4. Rodar em um celular Android

1. No celular, ative **Opções do desenvolvedor** e **Depuração USB**.
2. Conecte o cabo USB e aceite a autorização mostrada no aparelho.
3. Confira a conexão:

```powershell
flutter devices
```

4. Inicie o EcoScan:

```powershell
flutter run
```

Ao abrir o mapa, permita a localização. Ao abrir o scanner, permita a câmera.

## 5. Gerar um APK para instalar

Para uma versão de teste otimizada:

```powershell
flutter build apk --release
```

O arquivo será criado em:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Antes de publicar na Play Store, configure uma chave de assinatura própria no Android. A base ainda usa a assinatura de desenvolvimento, adequada somente para testes.

## 6. Rodar no iPhone

A compilação para iPhone exige um Mac com Xcode. No Mac:

```bash
flutter pub get
flutter run
```

O projeto já está configurado para iOS 15.5 ou superior e contém as mensagens de permissão de câmera e localização.

## 7. Como os EcoPontos funcionam

1. O aplicativo pede a posição atual do celular.
2. Faz uma busca rápida e outra detalhada por locais de reciclagem e descarte no OpenStreetMap.
3. Ordena os locais pela distância até o usuário.
4. Ao arrastar o mapa, consulta a nova área automaticamente.
5. Os novos resultados são somados aos anteriores; por isso todos os EcoPontos encontrados continuam visíveis.
6. O botão de atualização força uma nova consulta da área que está na tela.

As consultas públicas são suficientes para desenvolvimento. Para muitos usuários em produção, crie uma API intermediária com cache e siga as políticas de uso do Nominatim, Overpass e dos provedores de mapa.

## 8. Scanner e histórico

- A câmera só é iniciada quando a tela Scanner é aberta, reduzindo tempo e consumo.
- A resolução alta, o foco automático e a captura nativa ajudam a manter a imagem nítida.
- A classificação básica roda no aparelho e não exige uma conta.
- Fotos e resultados ficam na pasta privada do aplicativo.
- Excluir um registro também remove sua foto local.

## 9. Próximas integrações sugeridas

A estrutura ficou pronta para uma segunda etapa com:

- login e perfil;
- sincronização do histórico;
- cadastro e validação comunitária de EcoPontos;
- painel administrativo;
- modelo de IA treinado especificamente para resíduos;
- API própria para controlar cache, limites e qualidade dos locais.

Firebase ou Supabase podem ser conectados nessa etapa. Nenhuma senha ou chave secreta foi colocada nesta entrega.

## Soluções rápidas

### O mapa abriu, mas não mostrou pontos

- confira a internet;
- permita a localização;
- toque no botão de localização;
- mova o mapa para uma região urbana e toque em atualizar;
- algumas cidades ainda possuem poucos locais cadastrados no OpenStreetMap.

### A câmera não abre

- abra as configurações do celular;
- procure EcoScan AI;
- permita o acesso à câmera;
- feche e abra novamente o aplicativo.

### Erro relacionado a caminho com espaços

Mova o Flutter SDK para `C:\src\flutter` e atualize o `Path`. Depois rode:

```powershell
flutter clean
flutter pub get
```
