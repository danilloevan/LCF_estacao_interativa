/**
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
 */

import processing.serial.*;

Serial portaSerial;
boolean conectado = false;

// Dados recebidos do Arduino
float distancia = 100.0;     // em cm
int potValor = 512;          // 0 a 1023
int estadoAlerta = 0;        // 0 = Seguro, 1 = Atenção, 2 = Limite
int tiltAlerta = 0;          // 0 = Normal, 1 = Inclinado/Violado

// Histórico de pontos para rastro no radar
float anguloVarredura = 0;
float velocidadeVarredura = 0.04;

// Paleta interativa de cores (Processing -> Arduino)
color[] paletaCores = {
  color(255, 0, 0), // Vermelho
  color(0, 255, 0), // Verde
  color(0, 120, 255), // Azul
  color(255, 255, 0), // Amarelo
  color(255, 0, 255), // Magenta
  color(0, 255, 255), // Ciano
  color(255, 255, 255)    // Branco
};
int corSelecionadaIdx = -1;
String ultimoComandoEnviado = "Nenhum";
int feedbackTimer = 0;

void setup() {
  size(900, 600);
  smooth();

  // Lista portas seriais disponíveis no console
  println("Portas seriais disponíveis:");
  printArray(Serial.list());

  // Tentativa de conexão automática priorizando a COM8 do par virtual
  try {
    String portaEscolhida = "";
    for (String p : Serial.list()) {
      if (p.equalsIgnoreCase("COM8")) {
        portaEscolhida = p;
        break;
      }
    }
    if (portaEscolhida.equals("") && Serial.list().length > 0) {
      portaEscolhida = Serial.list()[0];
    }

    if (!portaEscolhida.equals("")) {
      portaSerial = new Serial(this, portaEscolhida, 9600);
      portaSerial.bufferUntil('\n');
      conectado = true;
      println("Conectado com sucesso na porta: " + portaEscolhida);
    } else {
      println("Aviso: Nenhuma porta serial encontrada.");
    }
  }
  catch (Exception e) {
    println("Erro ao conectar à porta serial: " + e.getMessage());
    conectado = false;
  }
}

void draw() {
  background(15, 20, 28);

  // Desenha painel do Radar
  desenharRadar(320, 310, 220);

  // Desenha painel lateral de Telemetria e Medidores
  desenharPainelLateral(600, 50, 270, 500);

  // Desenha cabeçalho superior
  desenharCabecalho();

  // Desenha seletor interativo de cores (Processing -> Arduino)
  desenharPaletaInterativa(50, 520);
}

// -------------------------------------------------------------------------------------
// Evento de recepção Serial (chamado automaticamente ao receber '\n')
// -------------------------------------------------------------------------------------
void serialEvent(Serial p) {
  try {
    String pacote = p.readStringUntil('\n');
    if (pacote != null) {
      pacote = trim(pacote);
      // Formato esperado: "DIST:25,POT:512,ALERT:1,TILT:0"
      String[] campos = split(pacote, ',');
      for (String campo : campos) {
        String[] par = split(campo, ':');
        if (par.length == 2) {
          String chave = trim(par[0]);
          String valor = trim(par[1]);
          if (chave.equals("DIST")) {
            distancia = float(valor);
          } else if (chave.equals("POT")) {
            potValor = int(valor);
            // Ajusta a velocidade de varredura do radar com o potenciômetro
            velocidadeVarredura = map(potValor, 0, 1023, 0.015, 0.08);
          } else if (chave.equals("ALERT")) {
            estadoAlerta = int(valor);
          } else if (chave.equals("TILT")) {
            tiltAlerta = int(valor);
          }
        }
      }
    }
  }
  catch (Exception e) {
    // Trata eventuais ruídos seriais sem interromper a execução
  }
}

// -------------------------------------------------------------------------------------
// Desenho do Radar Sonar
// -------------------------------------------------------------------------------------
void desenharRadar(float cx, float cy, float raio) {
  pushMatrix();
  translate(cx, cy);

  // Fundo do radar circular
  stroke(0, 180, 80, 60);
  fill(5, 30, 20, 180);
  ellipse(0, 0, raio * 2, raio * 2);

  // Círculos concêntricos de escala (ex: 50cm, 100cm, 150cm)
  strokeWeight(1);
  for (int r = 1; r <= 4; r++) {
    stroke(0, 255, 120, 40);
    noFill();
    ellipse(0, 0, (raio * 2 / 4) * r, (raio * 2 / 4) * r);
    fill(0, 200, 100, 120);
    textSize(10);
    text((r * 35) + "cm", 5, -(raio / 4) * r + 12);
    noFill();
  }

  // Linhas de mira cruzada
  stroke(0, 255, 120, 40);
  line(-raio, 0, raio, 0);
  line(0, -raio, 0, raio);

  // Linha de varredura rotativa
  anguloVarredura += velocidadeVarredura;
  float vx = cos(anguloVarredura) * raio;
  float vy = sin(anguloVarredura) * raio;
  stroke(0, 255, 150, 220);
  strokeWeight(2);
  line(0, 0, vx, vy);

  // Efeito rastro da varredura
  noStroke();
  for (int i = 0; i < 20; i++) {
    float a = anguloVarredura - (i * 0.03);
    fill(0, 255, 100, 60 - (i * 3));
    arc(0, 0, raio * 2, raio * 2, a - 0.04, a);
  }

  // Ponto de detecção do obstáculo (Blip)
  float raioMapeado = map(constrain(distancia, 5, 150), 0, 150, 0, raio);
  float px = cos(anguloVarredura) * raioMapeado;
  float py = sin(anguloVarredura) * raioMapeado;

  // Cor do Blip dependendo do alerta
  if (estadoAlerta == 2) {
    fill(255, 40, 40);
    stroke(255, 100, 100);
  } else if (estadoAlerta == 1) {
    fill(255, 200, 20);
    stroke(255, 230, 80);
  } else {
    fill(40, 255, 100);
    stroke(100, 255, 150);
  }
  strokeWeight(2);
  ellipse(px, py, 12, 12);

  // Pulso expansivo ao redor do obstáculo
  noFill();
  strokeWeight(1);
  ellipse(px, py, 18 + (frameCount % 10), 18 + (frameCount % 10));

  popMatrix();
}

// -------------------------------------------------------------------------------------
// Painel Lateral com Indicadores e Gráficos
// -------------------------------------------------------------------------------------
void desenharPainelLateral(float x, float y, float w, float h) {
  fill(25, 33, 46);
  stroke(40, 55, 75);
  strokeWeight(1.5);
  rect(x, y, w, h, 8);

  // Título do Card
  fill(220);
  textSize(15);
  textAlign(LEFT, TOP);
  text("PAINEL DE TELEMETRIA", x + 18, y + 15);

  // Status de Conexão
  textSize(11);
  if (conectado) {
    fill(50, 220, 100);
    text("● SERIAL CONECTADA (9600 bps)", x + 18, y + 36);
  } else {
    fill(255, 70, 70);
    text("● DESCONECTADO (AGUARDANDO SERIAL)", x + 18, y + 36);
  }

  // Linha divisória
  stroke(40, 55, 75);
  line(x + 15, y + 55, x + w - 15, y + 55);

  // Bloco 1: Distância HC-SR04
  fill(160, 175, 195);
  textSize(12);
  text("DISTÂNCIA (HC-SR04)", x + 18, y + 70);
  textSize(28);
  if (estadoAlerta == 2) fill(255, 70, 70);
  else if (estadoAlerta == 1) fill(255, 200, 40);
  else fill(50, 240, 130);
  text(nf(distancia, 1, 1) + " cm", x + 18, y + 90);

  // Bloco 2: Potenciômetro A0 (Barra de Progresso)
  fill(160, 175, 195);
  textSize(12);
  text("POTENCIÔMETRO (A0 / EMA)", x + 18, y + 145);
  textSize(14);
  fill(240);
  text("Valor: " + potValor + " / 1023", x + 18, y + 165);

  // Barra de nível
  noStroke();
  fill(40, 50, 68);
  rect(x + 18, y + 185, w - 36, 14, 4);
  float larguraBarra = map(potValor, 0, 1023, 0, w - 36);
  fill(0, 160, 255);
  rect(x + 18, y + 185, larguraBarra, 14, 4);

  // Bloco 3: Estado de Alerta e Tilt
  fill(160, 175, 195);
  textSize(12);
  text("ESTADO DO SISTEMA", x + 18, y + 225);

  // Badge de Estado
  noStroke();
  if (estadoAlerta == 2) {
    fill(220, 40, 40);
    rect(x + 18, y + 245, w - 36, 32, 6);
    fill(255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text("ALERTA: LIMITE DE SEGURANÇA", x + (w / 2), y + 261);
  } else if (estadoAlerta == 1) {
    fill(210, 160, 20);
    rect(x + 18, y + 245, w - 36, 32, 6);
    fill(20);
    textSize(14);
    textAlign(CENTER, CENTER);
    text("ATENÇÃO: APROXIMAÇÃO", x + (w / 2), y + 261);
  } else {
    fill(35, 160, 80);
    rect(x + 18, y + 245, w - 36, 32, 6);
    fill(255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text("SISTEMA SEGURO", x + (w / 2), y + 261);
  }

  // Alerta de Inclinação MPU6050
  textAlign(LEFT, TOP);
  if (tiltAlerta == 1) {
    fill(255, 60, 60);
    textSize(13);
    text("⚠ GABINETE INCLINADO / VIOLADO!", x + 18, y + 295);
  } else {
    fill(100, 200, 120);
    textSize(12);
    text("✓ Estabilidade Inercial OK (MPU6050)", x + 18, y + 295);
  }

  // Bloco 4: Feedback do Comando Serial de Cor
  stroke(40, 55, 75);
  line(x + 15, y + 335, x + w - 15, y + 335);

  fill(160, 175, 195);
  textSize(12);
  text("COMUNICAÇÃO BIDIRECIONAL", x + 18, y + 350);
  textSize(12);
  fill(200);
  text("Último comando enviado:", x + 18, y + 372);
  fill(0, 220, 255);
  text(ultimoComandoEnviado, x + 18, y + 392);

  if (feedbackTimer > 0) {
    fill(50, 255, 120);
    textSize(11);
    text("✔ Pacote transmitido com sucesso!", x + 18, y + 420);
    feedbackTimer--;
  }
}

// -------------------------------------------------------------------------------------
// Cabeçalho da Aplicação
// -------------------------------------------------------------------------------------
void desenharCabecalho() {
  fill(255);
  textSize(18);
  textAlign(LEFT, TOP);
  text("ESTAÇÃO INTERATIVA DE MONITORAMENTO E TELEMETRIA", 50, 20);
  fill(130, 150, 175);
  textSize(12);
  text("Computação Física — Integração Multimídia Arduino & Processing", 50, 44);
}

// -------------------------------------------------------------------------------------
// Paleta Interativa de Cores (Processing -> Arduino)
// -------------------------------------------------------------------------------------
void desenharPaletaInterativa(float x, float y) {
  fill(200);
  textSize(12);
  textAlign(LEFT, BASELINE);
  text("CLIQUE PARA ALTERAR A COR DO LED RGB NO ARDUINO (Processing -> Arduino):", x, y - 10);

  float tamanhoBtn = 32;
  float espaco = 12;

  for (int i = 0; i < paletaCores.length; i++) {
    float bx = x + (i * (tamanhoBtn + espaco));
    strokeWeight(corSelecionadaIdx == i ? 3 : 1.5);
    stroke(corSelecionadaIdx == i ? 255 : 80);
    fill(paletaCores[i]);
    rect(bx, y, tamanhoBtn, tamanhoBtn, 6);
  }
}

// -------------------------------------------------------------------------------------
// Tratamento de Interatividade com o Mouse
// -------------------------------------------------------------------------------------
void mousePressed() {
  float x = 50;
  float y = 520;
  float tamanhoBtn = 32;
  float espaco = 12;

  // Verifica se o clique foi em algum botão da paleta
  for (int i = 0; i < paletaCores.length; i++) {
    float bx = x + (i * (tamanhoBtn + espaco));
    if (mouseX >= bx && mouseX <= bx + tamanhoBtn && mouseY >= y && mouseY <= y + tamanhoBtn) {
      corSelecionadaIdx = i;
      color c = paletaCores[i];
      int r = int(red(c));
      int g = int(green(c));
      int b = int(blue(c));

      // Monta o protocolo especificado: "COLOR:r,g,b\n"
      String comando = "COLOR:" + r + "," + g + "," + b + "\n";
      ultimoComandoEnviado = comando.trim();
      feedbackTimer = 60; // Mostra aviso de envio por ~1 segundo

      // Envia via serial se conectado
      if (conectado && portaSerial != null) {
        portaSerial.write(comando);
        println("Enviado para o Arduino: " + comando);
      } else {
        println("Aviso: Porta serial não conectada.");
      }
    }
  }
}
