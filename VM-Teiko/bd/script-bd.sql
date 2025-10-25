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
  data_nascimento DATE NULL,
  genero VARCHAR(20) NULL,
  imagem_url VARCHAR(500) NULL,
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
  nome VARCHAR(20) NULL,
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
  categoria VARCHAR(70),
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX produto_fornada_idx (produto ASC) VISIBLE
);

-- -----------------------------------------------------
-- Table teiko.imagem_produto_fornada
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS imagem_produto_fornada (
    id INT NOT NULL AUTO_INCREMENT,
    produto_fornada_id INT NOT NULL,
    url VARCHAR(500) NOT NULL,
    PRIMARY KEY (id),
    INDEX produto_fornada_idx (produto_fornada_id ASC),
    CONSTRAINT fk_imagem_produto_fornada FOREIGN KEY (produto_fornada_id)
    REFERENCES produto_fornada (id)
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
  endereco_id INT NULL,
  usuario_id INT NULL,
  quantidade INT NOT NULL,
  data_previsao_entrega DATE NOT NULL,
  is_ativo TINYINT NULL,
  tipo_entrega VARCHAR(15) NOT NULL DEFAULT 'ENTREGA',
  nome_cliente VARCHAR(100) NOT NULL,
  telefone_cliente VARCHAR(20) NOT NULL,
  horario_retirada VARCHAR(10) NULL,
  observacoes VARCHAR(500) NULL,
  PRIMARY KEY (id),
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
  observacao VARCHAR(70),
  nome varchar(70),
  is_ativo TINYINT NULL,
  PRIMARY KEY (id)
);

-- -----------------------------------------------------
-- Table teiko.imagem_decoracao
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.imagem_decoracao (
    id INT NOT NULL AUTO_INCREMENT,
    decoracao_id INT NOT NULL,
    url VARCHAR(500) NOT NULL,
    PRIMARY KEY (id),
    INDEX decoracao_idx (decoracao_id ASC),
    CONSTRAINT fk_imagem_decoracao_decoracao FOREIGN KEY (decoracao_id)
    REFERENCES teiko.decoracao (id)
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
  id INT NOT NULL AUTO_INCREMENT,
  recheio_pedido_id INT NOT NULL,
  massa_id INT NOT NULL,
  cobertura_id INT NOT NULL,
  decoracao_id INT NULL,
  formato VARCHAR(45) NULL,
  tamanho VARCHAR(45) NULL,
  categoria VARCHAR(60),
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
  id INT NOT NULL AUTO_INCREMENT,
  endereco_id INT NULL,
  bolo_id INT NOT NULL,
  usuario_id INT NULL,
  observacao VARCHAR(70) NULL,
  data_previsao_entrega DATE NOT NULL,
  data_ultima_atualizacao DATETIME NOT NULL,
  tipo_entrega VARCHAR(15) NOT NULL DEFAULT 'ENTREGA',
  nome_cliente VARCHAR(100) NOT NULL,
  telefone_cliente VARCHAR(20) NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX fk_pedido_bolo_usuario1_idx (usuario_id ASC) VISIBLE,
  INDEX fk_pedido_bolo_endereco1_idx (endereco_id ASC) VISIBLE,
  INDEX fk_pedido_bolo_Bolo1_idx (bolo_id ASC) VISIBLE,
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

alter table recheio_unitario modify column sabor varchar(255);
alter table recheio_unitario modify column descricao varchar(255);
alter table recheio_exclusivo modify column nome varchar(255);

INSERT INTO teiko.recheio_unitario (sabor, descricao, valor, is_ativo) VALUES
    ('creamcheese_frosting', 'Creamcheese Frosting', 10.00, 1),
    ('devil_s_cake_ganache_meio_amargo', 'Devil''s Cake (Ganache meio-amargo)', 10.00, 1),
    ('zanza_ganache_meio_amargo_e_reducao_de_frutas_vermelhas', 'Zanza (Ganache meio-amargo e redução de frutas vermelhas)', 10.00, 1),
    ('brunna_brigadeiro_de_limao_siciliano', 'Brunna (Brigadeiro de limão siciliano)', 10.00, 1),
    ('marilia_brigadeiro_meio_amargo', 'Marilia (Brigadeiro meio-amargo)', 10.00, 1),
    ('hugo_brigadeiro_meio_amargo_e_brigadeiro_de_ninho', 'Hugo (Brigadeiro meio-amargo e Brigadeiro de ninho)', 10.00, 1),
    ('bia_benego_cocada_cremosa_de_coco_queimado', 'Bia Benego (Cocada cremosa de coco queimado)', 10.00, 1),
    ('duda_brigadeiro_de_doce_de_leite', 'Duda (Brigadeiro de Doce de leite)', 10.00, 1),
    ('giovanna_brigadeiro_de_pistache', 'Giovanna (Brigadeiro de Pistache)', 10.00, 1),
    ('juliana_creme_4_leites_e_reducao_de_frutas_vermelhas', 'Juliana (Creme 4 leites e redução de frutas vermelhas)', 10.00, 1),
    ('ana_brigadeiro_de_limao_siciliano_e_reducao_de_frutas_vermelhas', 'Ana (Brigadeiro de limão siciliano e redução de frutas vermelhas)', 10.00, 1),
    ('stefan_brigadeiro_de_pistache_e_brigadeiro_de_limao_siciliano', 'Stefan (Brigadeiro de pistache e Brigadeiro de limão siciliano)', 10.00, 1),
    ('dora_brigadeiro_de_ninho_e_reducao_de_frutas_vermelhas', 'Dora (Brigadeiro de ninho e redução de frutas vermelhas)', 10.00, 1),
    ('gislaine_brigadeiro_meio_amargo_e_reducao_de_morango', 'Gislaine (Brigadeiro meio-amargo e redução de morango)', 10.00, 1),
    ('nancy_cocada_cremosa_e_compota_de_abacaxi', 'Nancy (Cocada cremosa e compota de abacaxi)', 10.00, 1),
    ('priscila_ganache_caramelo_salgado_e_amendoim_tostado', 'Priscila (Ganache, caramelo salgado e amendoim tostado)', 10.00, 1),
    ('sara_brigadeiro_de_maracuja_e_ganache_meio_amargo', 'Sara (Brigadeiro de maracujá e Ganache meio-amargo)', 10.00, 1),
    ('tiramissu_creamcheese_frosting_e_nuvem_de_cacau', 'Tiramissu (Creamcheese frosting e nuvem de cacau)', 10.00, 1),
    ('joao_donato_ganache_meio_amargo_e_cupuacu', 'João Donato (Ganache meio-amargo e cupuaçu)', 10.00, 1);
    
INSERT INTO teiko.massa (sabor, valor, is_ativo) VALUES
    ('cacau', 5.00, 1),
    ('cacau_expresso', 5.00, 1),
    ('baunilha', 5.00, 1),
    ('red_velvet', 5.00, 1);
    
select * from teiko.usuario;

-- =====================================================



INSERT INTO teiko.cobertura (cor, descricao, is_ativo) VALUES
  ('Branco', 'Cobertura cremosa de baunilha', 1),
  ('Preto', 'Cobertura de chocolate meio amargo', 1),
  ('Rosa', 'Cobertura de morango com brilho', 1);


INSERT INTO teiko.decoracao (observacao, nome, is_ativo) VALUES
  ('Decoração com flores naturais', 'Flores Silvestres', 1),
  ('Decoração com tema de festa junina', 'Festa Junina', 1),
  ('Decoração com tema de aniversário infantil', 'Aniversário Infantil', 1);


INSERT INTO teiko.imagem_decoracao (decoracao_id, url) VALUES
  (1, ''),
  (2, 'https://carambolostorage.blob.core.windows.net/teiko-s3/9a0b4e7d-e30b-4814-9760-edf789a7aaeb_TOMATE.pnga'),
  (3, 'https://carambolostorage.blob.core.windows.net/teiko-s3/9a0b4e7d-e30b-4814-9760-edf789a7aaeb_TOMATE.png');


INSERT INTO teiko.recheio_exclusivo (recheio_unitario_id1, recheio_unitario_id2, nome, is_ativo) VALUES
  (39, 40, 'Creamcheese Frosting com Devil`s Cake (Ganache meio-amargo)', 1),
  (39, 41, 'Creamcheese Frosting com Zanza (Ganache meio-amargo e redução de frutas vermelhas)', 1),
  (41, 40, 'Zanza (Ganache meio-amargo e redução de frutas vermelhas) com Devil`s Cake (Ganache meio-amargo)', 1);


INSERT INTO teiko.recheio_pedido (recheio_unitario_id1, recheio_unitario_id2, recheio_exclusivo, is_ativo) VALUES
  (39, 40, NULL, 1),
  (NULL, NULL, 4, 1),
  (41, 42, NULL, 1);

INSERT INTO teiko.bolo (recheio_pedido_id, massa_id, cobertura_id, decoracao_id, formato, tamanho, categoria, is_ativo) VALUES
  (1, 1, 1, 1, 'CIRCULO', 'TAMANHO_5', 'Aniversário', 1),
  (2, 2, 2, 2, 'CORACAO', 'TAMANHO_7', 'Casamento', 1),
  (3, 3, 3, 3, 'CIRCULO', 'TAMANHO_12', 'Festa Junina', 1);


INSERT INTO teiko.pedido_bolo (endereco_id, bolo_id, usuario_id, observacao, data_previsao_entrega, data_ultima_atualizacao, tipo_entrega, nome_cliente, telefone_cliente, is_ativo) VALUES
  (1, 1, 1, 'Sem cobertura de chocolate', '2025-06-15', NOW(), 'ENTREGA', 'João Silva', '11987654321', 1),
  (null, 2, 1, 'Com tema de casamento', '2025-06-20', NOW(), 'RETIRADA', 'Maria Oliveira', '11912345678', 1),
  (1, 3, null, 'Com tema de festa junina', '2025-06-25', NOW(), 'ENTREGA', 'Carlos Souza', '11998765432', 1);

select * from teiko.pedido_bolo;

INSERT INTO teiko.resumo_pedido (status, valor, data_pedido, data_entrega, pedido_fornada_id, pedido_bolo_id, is_ativo) VALUES
  ('PENDENTE', 100.00, NOW(), '2025-06-15', NULL, 7, 1),
  ('PAGO', 150.00, NOW(), '2025-06-20', NULL, 8, 1),
  ('CONCLUIDO', 120.00, NOW(), '2025-06-25', NULL, 9, 1);
    
    update bolo set categoria ='Carambolo';
    select * from produto_fornada;
    
    
    
    ALTER TABLE teiko.endereco 
  MODIFY COLUMN cep VARCHAR(128) NOT NULL,
  MODIFY COLUMN estado VARCHAR(256) NOT NULL,
  MODIFY COLUMN cidade VARCHAR(256) NOT NULL,
  MODIFY COLUMN bairro VARCHAR(256) NOT NULL,
  MODIFY COLUMN logradouro VARCHAR(256) NOT NULL,
  MODIFY COLUMN numero VARCHAR(128) NOT NULL,
  MODIFY COLUMN complemento VARCHAR(256) NULL,
  MODIFY COLUMN referencia VARCHAR(256) NULL;

ALTER TABLE teiko.pedido_bolo 
  MODIFY COLUMN nome_cliente VARCHAR(256) NOT NULL,
  MODIFY COLUMN telefone_cliente VARCHAR(256) NOT NULL;

ALTER TABLE teiko.pedido_fornada 
  MODIFY COLUMN nome_cliente VARCHAR(256) NOT NULL,
  MODIFY COLUMN telefone_cliente VARCHAR(256) NOT NULL;
  
  
  
  
  ALTER TABLE teiko.endereco 
  ADD COLUMN dedup_hash VARCHAR(64) NULL,
  ADD INDEX dedup_hash_idx (dedup_hash ASC),
  MODIFY COLUMN cep VARCHAR(128) NOT NULL,
  MODIFY COLUMN estado VARCHAR(256) NOT NULL,
  MODIFY COLUMN cidade VARCHAR(256) NOT NULL,
  MODIFY COLUMN bairro VARCHAR(256) NOT NULL,
  MODIFY COLUMN logradouro VARCHAR(256) NOT NULL,
  MODIFY COLUMN numero VARCHAR(128) NOT NULL,
  MODIFY COLUMN complemento VARCHAR(256) NULL,
  MODIFY COLUMN referencia VARCHAR(256) NULL;

ALTER TABLE teiko.pedido_bolo 
  MODIFY COLUMN nome_cliente VARCHAR(256) NOT NULL,
  MODIFY COLUMN telefone_cliente VARCHAR(256) NOT NULL;

ALTER TABLE teiko.pedido_fornada 
  MODIFY COLUMN nome_cliente VARCHAR(256) NOT NULL,
  MODIFY COLUMN telefone_cliente VARCHAR(256) NOT NULL;
  
  -- Endereços mais recentes (campos devem parecer Base64)
SELECT id, cep, estado, cidade, bairro, logradouro, numero, complemento, referencia
FROM teiko.endereco
ORDER BY id DESC
LIMIT 5;

-- Pedido de bolo mais recente (nome/telefone cifrados)
SELECT id, nome_cliente, telefone_cliente
FROM teiko.pedido_bolo
ORDER BY id DESC
LIMIT 5;

SELECT id, cep
FROM teiko.endereco
WHERE cep REGEXP '^[A-Za-z0-9+/=]{24,}$'
ORDER BY id DESC
LIMIT 10;

select * from teiko.endereco;

insert into teiko.usuario(id, nome, senha, contato, sys_admin)
values (10, "Murilo", "henpaaySad98!", "5511912345671", 1);