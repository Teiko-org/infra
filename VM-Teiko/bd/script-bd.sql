CREATE DATABASE IF NOT EXISTS teiko;
USE teiko ;
-- -----------------------------------------------------
-- Table teiko.usuario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.usuario (
  id INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(60) NOT NULL,
  senha VARCHAR(60) NOT NULL,
  contato VARCHAR(14) NOT NULL,
  sys_admin TINYINT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX nome_idx (nome ASC) VISIBLE,
  INDEX contato_idx (contato ASC) VISIBLE
);

-- -----------------------------------------------------
-- Table teiko.endereco
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.endereco (
  id INT NOT NULL AUTO_INCREMENT,
  cep CHAR(8) NOT NULL,
  estado VARCHAR(20) NOT NULL,
  cidade VARCHAR(100) NOT NULL,
  bairro VARCHAR(100) NOT NULL,
  logradouro VARCHAR(100) NOT NULL,
  numero VARCHAR(6) NOT NULL,
  complemento VARCHAR(20) NULL,
  referencia VARCHAR(70) NULL,
  usuario_id INT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX fk_endereco_usuario1_idx (usuario_id ASC) VISIBLE,
  INDEX cep_idx (cep ASC) VISIBLE,
  CONSTRAINT fk_endereco_usuario1
    FOREIGN KEY (usuario_id)
    REFERENCES teiko.usuario (id)
);

-- -----------------------------------------------------
-- Table teiko.produto_fornada
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.produto_fornada (
  id INT NOT NULL AUTO_INCREMENT,
  produto VARCHAR(50) NULL,
  descricao VARCHAR(70) NULL,
  valor DOUBLE NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX produto_fornada_idx (produto ASC) VISIBLE
);


-- -----------------------------------------------------
-- Table teiko.fornada
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.fornada (
  id INT NOT NULL AUTO_INCREMENT,
  data_inicio DATE NULL,
  data_fim DATE NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX data_inicio_idx (data_inicio ASC) VISIBLE,
  INDEX data_fim_idx (data_fim ASC) VISIBLE
);

-- -----------------------------------------------------
-- Table teiko.fornada_da_vez
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.fornada_da_vez (
  id INT NOT NULL AUTO_INCREMENT,
  produto_fornada_id INT NOT NULL,
  fornada_id INT NOT NULL,
  quantidade INT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id, produto_fornada_id, fornada_id),
  INDEX fornada_idx (fornada_id ASC) VISIBLE,
  INDEX produto_fornada_idx (produto_fornada_id ASC) VISIBLE,
  CONSTRAINT fk_produto_fornada
    FOREIGN KEY (produto_fornada_id)
    REFERENCES teiko.produto_fornada (id),
  CONSTRAINT fk_fornada
    FOREIGN KEY (fornada_id)
    REFERENCES teiko.fornada (id)
);

-- -----------------------------------------------------
-- Table teiko.pedido_fornada
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.pedido_fornada (
  id INT NOT NULL AUTO_INCREMENT,
  fornada_da_vez_id INT NOT NULL,
  endereco_id INT NOT NULL,
  usuario_id INT NULL,
  quantidade INT NOT NULL,
  data_previsao_entrega DATE NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id, fornada_da_vez_id, endereco_id),
  INDEX endereco1_idx (endereco_id ASC) VISIBLE,
  INDEX usuario1_idx (usuario_id ASC) VISIBLE,
  INDEX fornada_da_vez1_idx (fornada_da_vez_id ASC) VISIBLE,
  CONSTRAINT fk_pedido_fornada_endereco1
    FOREIGN KEY (endereco_id)
    REFERENCES teiko.endereco (id),
  CONSTRAINT fk_pedido_fornada_usuario1
    FOREIGN KEY (usuario_id)
    REFERENCES teiko.usuario (id),
  CONSTRAINT fk_pedido_fornada_fornada_da_vez1
    FOREIGN KEY (fornada_da_vez_id)
    REFERENCES teiko.fornada_da_vez (id)
);

-- -----------------------------------------------------
-- Table teiko.massa
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.massa (
  id INT NOT NULL AUTO_INCREMENT,
  sabor VARCHAR(50) NOT NULL,
  valor DOUBLE NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Table teiko.cobertura
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.cobertura (
  id INT NOT NULL AUTO_INCREMENT,
  cor VARCHAR(20) NOT NULL,
  descricao VARCHAR(70) NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Table teiko.decoracao
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.decoracao (
  id INT NOT NULL AUTO_INCREMENT,
  imagem_referencia BLOB NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Table teiko.recheio_unitario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.recheio_unitario (
  id INT NOT NULL AUTO_INCREMENT,
  sabor VARCHAR(50) NOT NULL,
  descricao VARCHAR(70) NULL,
  valor DOUBLE NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Table teiko.recheio_exclusivo
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.recheio_exclusivo (
  id INT NOT NULL AUTO_INCREMENT,
  recheio_unitario_id1 INT NOT NULL,
  recheio_unitario_id2 INT NOT NULL,
  nome VARCHAR(50) NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id, recheio_unitario_id1, recheio_unitario_id2),
  INDEX recheio_unitario1_idx (recheio_unitario_id1 ASC) VISIBLE,
  INDEX recheio_unitario2_idx (recheio_unitario_id2 ASC) VISIBLE,
  CONSTRAINT fk_recheio_exclusivo_recheio_unitario1
    FOREIGN KEY (recheio_unitario_id1)
    REFERENCES teiko.recheio_unitario (id),
  CONSTRAINT fk_recheio_exclusivo_recheio_unitario2
    FOREIGN KEY (recheio_unitario_id2)
    REFERENCES teiko.recheio_unitario (id)
);

-- -----------------------------------------------------
-- Table teiko.recheio_pedido
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.recheio_pedido (
  id INT NOT NULL AUTO_INCREMENT,
  recheio_unitario_id1 INT NULL,
  recheio_unitario_id2 INT NULL,
  recheio_exclusivo INT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX exclusivo1_idx (recheio_exclusivo ASC) VISIBLE,
  CONSTRAINT fk_unitario1
    FOREIGN KEY (recheio_unitario_id1)
    REFERENCES teiko.recheio_unitario (id),
  CONSTRAINT fk_unitario2
    FOREIGN KEY (recheio_unitario_id2)
    REFERENCES teiko.recheio_unitario (id),
  CONSTRAINT fk_recheio_exclusivo1
    FOREIGN KEY (recheio_exclusivo)
    REFERENCES teiko.recheio_exclusivo (id)
);

-- -----------------------------------------------------
-- Table teiko.bolo
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS teiko.bolo (
  id INT NOT NULL,
  recheio_pedido_id INT NOT NULL,
  massa_id INT NOT NULL,
  cobertura_id INT NOT NULL,
  decoracao_id INT NULL,
  formato VARCHAR(45) NULL,
  tamanho INT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id, recheio_pedido_id, massa_id, cobertura_id),
  INDEX fk_Bolo_massa1_idx (massa_id ASC) VISIBLE,
  INDEX fk_Bolo_decoracao1_idx (decoracao_id ASC) VISIBLE,
  INDEX fk_Bolo_cobertura1_idx (cobertura_id ASC) VISIBLE,
  CONSTRAINT fk_Bolo_recheio_pedido1
    FOREIGN KEY (recheio_pedido_id)
    REFERENCES teiko.recheio_pedido (id),
  CONSTRAINT fk_Bolo_massa1
    FOREIGN KEY (massa_id)
    REFERENCES teiko.massa (id),
  CONSTRAINT fk_Bolo_decoracao1
    FOREIGN KEY (decoracao_id)
    REFERENCES teiko.decoracao (id),
  CONSTRAINT fk_Bolo_cobertura1
    FOREIGN KEY (cobertura_id)
    REFERENCES teiko.cobertura (id)
);

-- -----------------------------------------------------
-- Table teiko.pedido_bolo
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS teiko.pedido_bolo (
  id INT NOT NULL,
  endereco_id INT NOT NULL,
  bolo_id INT NOT NULL,
  usuario_id INT NULL,
  observacao VARCHAR(70) NULL,
  data_previsao_entrega DATE NOT NULL,
  data_ultima_atualizacao DATETIME NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id, endereco_id, Bolo_id),
  INDEX fk_pedido_bolo_usuario1_idx (usuario_id ASC) VISIBLE,
  INDEX fk_pedido_bolo_endereco1_idx (endereco_id ASC) VISIBLE,
  INDEX fk_pedido_bolo_Bolo1_idx (Bolo_id ASC) VISIBLE,
  CONSTRAINT fk_pedido_bolo_usuario1
    FOREIGN KEY (usuario_id)
    REFERENCES teiko.usuario (id),
  CONSTRAINT fk_pedido_bolo_endereco1
    FOREIGN KEY (endereco_id)
    REFERENCES teiko.endereco (id),
  CONSTRAINT fk_pedido_bolo_Bolo1
    FOREIGN KEY (bolo_id)
    REFERENCES teiko.bolo (id)
);

-- -----------------------------------------------------
-- Table teiko.resumo_pedido
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.resumo_pedido (
  id INT NOT NULL AUTO_INCREMENT,
  status VARCHAR(45) NOT NULL,
  valor DOUBLE NOT NULL,
  data_pedido DATETIME NOT NULL,
  data_entrega DATETIME NULL,
  pedido_fornada_id INT NULL,
  pedido_bolo_id INT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX fk_fornada1_idx (pedido_fornada_id ASC) VISIBLE,
  INDEX fk_pedido_bolo1_idx (pedido_bolo_id ASC) VISIBLE,
  CONSTRAINT fk_resumo_pedido_pedido_fornada1
    FOREIGN KEY (pedido_fornada_id)
    REFERENCES teiko.pedido_fornada (id),
  CONSTRAINT fk_resumo_pedido_pedido_bolo1
    FOREIGN KEY (pedido_bolo_id)
    REFERENCES teiko.pedido_bolo (id)
);