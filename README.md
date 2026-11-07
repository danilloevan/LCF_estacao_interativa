# LCF_estacao_interativa
 * =====================================================================================
 * Projeto: Estação Interativa de Monitoramento de Segurança e Telemetria Multimídia
 * Autor: Danillo Evangelista
 * Aplicação: Interface Gráfica Interativa em Processing (PDE)
 * Disciplina: Computação Física
 *
 * Funcionalidades:
 * 1. Conexão Serial com Arduino (9600 baud).
 * 2. Radar Sonar em tempo real baseado na distância (DIST).
 * 3. Indicador de sensibilidade/velocidade analógica (POT).
 * 4. Alertas visuais de segurança (SEGURO, ATENÇÃO, LIMITE, TILT).
 * 5. Envio bidirecional: Clique na paleta interativa envia "COLOR:r,g,b\n" para o Arduino.
 * =====================================================================================



## 🔌 Como Rodar a Simulação e a Comunicação Serial (Wokwi + VSPE + Processing)

Para integrar a simulação do **Wokwi** com a interface gráfica do **Processing** sem precisar de uma placa física conectada à USB, utilizei um par de portas virtuais com o **VSPE (Virtual Serial Ports Emulator)** e a **Web Serial API** do navegador.

---

### 🗺️ Fluxo de Comunicação
---

### Passo 1: Download e Instalação do VSPE

1. Baixe o instalador do **VSPE (Virtual Serial Ports Emulator)** da Eterlogic:
   - [Download VSPE oficial](https://eterlogic.com/Products.VSPE.html)
2. Instale o programa no seu computador.
3. **Importante:** Sempre abra o VSPE executando como **Administrador** (botão direito no atalho `->` *Executar como administrador*).

---

### Passo 2: Criar o Par de Portas Seriais (Pair) no VSPE

1. Abra o **VSPE** executando como **Administrador**.
2. Clique no ícone de **Criar Novo Dispositivo** (ou menu `Device -> Create`).
3. Em **Device type**, selecione: **`Pair`** e clique em **Avançar**.
4. Defina as duas portas que formarão a ponte:
   - **Virtual serial port 1:** `COM7` *(para o Wokwi)*
   - **Virtual serial port 2:** `COM8` *(para o Processing)*
5. Clique em **Concluir (Finish)** e certifique-se de que o status esteja como **`OK` / `Initialized`**.
6. **Mantenha o VSPE aberto** em segundo plano durante todo o uso.

---

### Passo 3: Iniciar a Simulação no Wokwi

1. Abra o projeto no **Wokwi** (utilizando Google Chrome ou Microsoft Edge).
2. Clique no botão verde de **Play (Iniciar Simulação)**.
3. O navegador exibirá a janela pop-up:
   > **"wokwi.com quer se conectar a uma porta serial"**
4. Na lista de dispositivos:
   - Selecione: **`Eterlogic Virtual Serial Port (COM7): pareado`**.
   - Clique em **Conectar**.
5. O Wokwi passará a transmitir a telemetria contínua pela `COM7`.

---

### Passo 4: Executar a Interface no Processing

1. Abra o arquivo `processing_telemetria.pde` no **Processing 4**.
2. Pressione **Play / Run (Ctrl + R)**.
3. O Processing se conectará automaticamente à porta `COM8` a 9600 baud.
4. **Interatividade em tempo real:**
   - 📡 O radar gráfico renderiza os obstáculos detectados pelo sensor ultrassônico.
   - 🎛️ Os medidores exibem a posição do potenciômetro e alertas de inclinação (MPU6050).
   - 🎨 **Envio bidirecional:** Clique em qualquer cor da paleta inferior da janela para enviar o comando serial (`COLOR:R,G,B`) de volta ao Arduino simulado no Wokwi, alterando a cor do LED RGB imediatamente.
