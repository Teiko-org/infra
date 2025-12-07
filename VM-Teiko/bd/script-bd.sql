-- =====================================================
-- SCRIPT COMPLETO DO BANCO DE DADOS TEIKO - VERSÃO COM IMAGENS
-- =====================================================

/*!40101 SET NAMES utf8mb4 */;

CREATE DATABASE IF NOT EXISTS teiko DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE teiko;

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
-- Table teiko.jwt_token_blacklist
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.jwt_token_blacklist (
  id INT NOT NULL AUTO_INCREMENT,
  token VARCHAR(500) NOT NULL,
  blacklisted_at DATETIME NOT NULL,
  PRIMARY KEY (id),
  INDEX token_idx (token ASC) VISIBLE
);

-- -----------------------------------------------------
-- Table teiko.carrinho
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.carrinho (
  id INT NOT NULL AUTO_INCREMENT,
  usuario_id INT NOT NULL,
  itens TEXT NULL,
  data_ultima_atualizacao DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_carrinho_usuario (usuario_id),
  INDEX fk_carrinho_usuario_idx (usuario_id ASC) VISIBLE,
  CONSTRAINT fk_carrinho_usuario
    FOREIGN KEY (usuario_id)
    REFERENCES teiko.usuario (id)
    ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Table teiko.endereco
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.endereco (
  id INT NOT NULL AUTO_INCREMENT,
  nome VARCHAR(20) NULL,
  cep VARCHAR(128) NOT NULL,
  estado VARCHAR(256) NOT NULL,
  cidade VARCHAR(256) NOT NULL,
  bairro VARCHAR(256) NOT NULL,
  logradouro VARCHAR(256) NOT NULL,
  numero VARCHAR(128) NOT NULL,
  complemento VARCHAR(256) NULL,
  referencia VARCHAR(256) NULL,
  usuario_id INT NULL,
  is_ativo TINYINT NULL,
  dedup_hash VARCHAR(64) NULL,
  PRIMARY KEY (id),
  INDEX fk_endereco_usuario1_idx (usuario_id ASC) VISIBLE,
  INDEX cep_idx (cep ASC) VISIBLE,
  INDEX dedup_hash_idx (dedup_hash ASC) VISIBLE,
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
CREATE TABLE IF NOT EXISTS teiko.imagem_produto_fornada (
    id INT NOT NULL AUTO_INCREMENT,
    produto_fornada_id INT NOT NULL,
    url VARCHAR(500) NOT NULL,
    PRIMARY KEY (id),
    INDEX produto_fornada_idx (produto_fornada_id ASC),
    CONSTRAINT fk_imagem_produto_fornada FOREIGN KEY (produto_fornada_id)
    REFERENCES teiko.produto_fornada (id)
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
  nome_cliente VARCHAR(256) NOT NULL,
  telefone_cliente VARCHAR(256) NOT NULL,
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
  sabor VARCHAR(255) NOT NULL,
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
  nome VARCHAR(70),
  categoria VARCHAR(70),
  is_ativo TINYINT NULL,
  PRIMARY KEY (id)
);

-- Alias para compatibilidade com queries antigas que referenciam "decoracaoEntity"
-- (mantém os mesmos campos de teiko.decoracao)
CREATE TABLE IF NOT EXISTS teiko.decoracaoEntity LIKE teiko.decoracao;
INSERT IGNORE INTO teiko.decoracaoEntity SELECT * FROM teiko.decoracao;

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

CREATE TABLE IF NOT EXISTS teiko.adicional (
	id INT NOT NULL AUTO_INCREMENT,
    descricao VARCHAR(90),
    is_ativo TINYINT NULL,
	PRIMARY KEY (id),
    INDEX adicional_idx (id ASC)
);

CREATE TABLE IF NOT EXISTS teiko.adicional_decoracao (
	id INT NOT NULL AUTO_INCREMENT,
	decoracao_id INT NOT NULL,
    adicional_id INT NOT NULL,

    PRIMARY KEY (id),
    CONSTRAINT fk_decoracao_id_ad
		FOREIGN KEY (decoracao_id)
        REFERENCES teiko.decoracao (id),
	CONSTRAINT fk_adicional_id_ad
		FOREIGN KEY (adicional_id)
        REFERENCES teiko.adicional(id)
);

-- -----------------------------------------------------
-- Table teiko.recheio_unitario
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS teiko.recheio_unitario (
  id INT NOT NULL AUTO_INCREMENT,
  sabor VARCHAR(255) NOT NULL,
  descricao VARCHAR(255) NULL,
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
  nome VARCHAR(255) NOT NULL,
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
  nome_cliente VARCHAR(256) NOT NULL,
  telefone_cliente VARCHAR(256) NOT NULL,
  is_ativo TINYINT NULL,
  PRIMARY KEY (id),
  INDEX fk_pedido_bolo_usuario1_idx (usuario_id ASC) VISIBLE,
  INDEX fk_pedido_bolo_endereco1_idx (endereco_id ASC) VISIBLE,
  INDEX fk_Bolo1_idx (bolo_id ASC) VISIBLE,
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

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Usuários
INSERT INTO teiko.usuario (nome, senha, contato, sys_admin, is_ativo) VALUES
('Admin Sistema', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', '11999999999', 1, 1),
('Murilo', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', '5511912345671', 1, 1),
('João Souza', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', '11988888888', 0, 1),
('Ana Oliveira', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVEFDi', '11977777777', 0, 1);

-- Endereços
INSERT INTO teiko.endereco (cep, estado, cidade, bairro, logradouro, numero, complemento, referencia, usuario_id, is_ativo) VALUES
('01234567', 'SP', 'São Paulo', 'Centro', 'Rua A', '100', NULL, 'Perto da praça', 1, 1),
('76543210', 'SP', 'São Paulo', 'Bela Vista', 'Rua B', '200', NULL, 'Próximo ao mercado', 2, 1),
('12345678', 'SP', 'São Paulo', 'Pinheiros', 'Rua C', '300', NULL, NULL, 3, 1);

-- Produtos Fornada
INSERT INTO teiko.produto_fornada (produto, descricao, valor, categoria, is_ativo) VALUES
('Pão de Queijo', 'Pão de queijo artesanal', 8.00, 'Salgados', 1),
('Pão Francês', 'Pão francês crocante', 5.00, 'Padaria', 1),
('Croissant', 'Croissant de manteiga', 12.00, 'Salgados', 1),
('Brioche', 'Brioche doce', 10.00, 'Doces', 1);

-- Imagens dos Produtos Fornada
INSERT INTO teiko.imagem_produto_fornada (produto_fornada_id, url) VALUES
-- Pão de Queijo
(1, 'https://picsum.photos/seed/paoqueijo1/320/320'),
(1, 'https://picsum.photos/seed/paoqueijo2/320/320'),
-- Pão Francês
(2, 'https://picsum.photos/seed/paofrances1/320/320'),
(2, 'https://picsum.photos/seed/paofrances2/320/320'),
-- Croissant
(3, 'https://picsum.photos/seed/croissant1/320/320'),
(3, 'https://picsum.photos/seed/croissant2/320/320'),
-- Brioche
(4, 'https://picsum.photos/seed/brioche1/320/320'),
(4, 'https://picsum.photos/seed/brioche2/320/320');

-- Fornadas
INSERT INTO teiko.fornada (data_inicio, data_fim, is_ativo) VALUES
('2024-12-01', '2024-12-02', 1),
('2024-12-03', '2024-12-04', 1),
('2024-12-05', '2024-12-06', 1);

-- Fornada da Vez
INSERT INTO teiko.fornada_da_vez (produto_fornada_id, fornada_id, quantidade, is_ativo) VALUES
(1, 1, 100, 1),
(2, 1, 100, 1),
(2, 2, 80, 1),
(3, 3, 50, 1),
(4, 3, 30, 1);

-- Pedidos Fornada adicionais
INSERT INTO teiko.pedido_fornada (fornada_da_vez_id, endereco_id, usuario_id, quantidade, data_previsao_entrega, tipo_entrega, nome_cliente, telefone_cliente, is_ativo) VALUES
(1, 1, 1, 90, '2024-12-12', 'ENTREGA', 'Cliente 1', '11911111111', 1),
(3, 2, 2, 50, '2024-12-06', 'RETIRADA', 'Cliente 2', '11922222222', 1),
(4, 3, 3, 30, '2024-12-06', 'RETIRADA', 'Cliente 3', '11933333333', 1),
(2, 1, 1, 5,  '2025-01-05', 'ENTREGA', 'Cliente 4', '11944444444', 1),
(2, 2, 2, 10, '2025-10-10', 'RETIRADA', 'Cliente 5', '11955555555', 1);

-- Massas
INSERT INTO teiko.massa (sabor, valor, is_ativo) VALUES
('cacau', 5.00, 1),
('cacau_expresso', 5.00, 1),
('baunilha', 5.00, 1),
('red_velvet', 5.00, 1);

-- Coberturas
INSERT INTO teiko.cobertura (cor, descricao, is_ativo) VALUES
('Branco', 'Cobertura cremosa de baunilha', 1),
('Preto', 'Cobertura de chocolate meio amargo', 1),
('Rosa', 'Cobertura de morango com brilho', 1);

-- Decorações
INSERT INTO teiko.decoracao (observacao, nome, categoria, is_ativo) VALUES
('Decoração com tema de festa junina', 'Flores Silvestres', 'Vintage', 1),
('Decoração com flores naturais', 'Festa Junina', 'Floral', 1),
('Decoração com tema de aniversário infantil', 'Aniversário Infantil', 'My Carambolo', 1),
('Decoração elegante para casamento', 'Casamento Elegante', 'Shag Cake', 1);

-- Imagens Decoração
INSERT INTO teiko.imagem_decoracao (decoracao_id, url) VALUES
(1, 'https://picsum.photos/seed/nature1/320/320'),
(1, 'https://picsum.photos/seed/nature2/320/320'),
(2, 'https://picsum.photos/seed/festajunina1/320/320'),
(2, 'https://picsum.photos/seed/festajunina2/320/320'),
(3, 'https://picsum.photos/seed/infantil1/320/320'),
(3, 'https://picsum.photos/seed/infantil2/320/320'),
(4, 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=320&h=320&fit=crop&crop=center'),
(4, 'https://picsum.photos/seed/casamento1/320/320');

-- Recheios Unitários
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

-- Recheios Exclusivos
INSERT INTO teiko.recheio_exclusivo (recheio_unitario_id1, recheio_unitario_id2, nome, is_ativo) VALUES
(1, 2, 'Creamcheese Frosting com Devil`s Cake (Ganache meio-amargo)', 1),
(1, 3, 'Creamcheese Frosting com Zanza (Ganache meio-amargo e redução de frutas vermelhas)', 1),
(3, 2, 'Zanza (Ganache meio-amargo e redução de frutas vermelhas) com Devil`s Cake (Ganache meio-amargo)', 1);

-- Recheios Pedido
INSERT INTO teiko.recheio_pedido (recheio_unitario_id1, recheio_unitario_id2, recheio_exclusivo, is_ativo) VALUES
(1, 2, NULL, 1),
(NULL, NULL, 1, 1),
(3, 4, NULL, 1),
(5, 6, NULL, 1),
(7, 8, NULL, 1),
(9, 10, NULL, 1),
(1, 3, NULL, 1),
(2, 4, NULL, 1);

-- Bolos com categorias diferentes
INSERT INTO teiko.bolo (recheio_pedido_id, massa_id, cobertura_id, decoracao_id, formato, tamanho, categoria, is_ativo) VALUES
(1, 1, 1, 1, 'CIRCULO', 'TAMANHO_5', 'Carambolo', 1),
(2, 2, 2, 2, 'CORACAO', 'TAMANHO_7', 'Casamento', 1),
(3, 3, 3, 3, 'CIRCULO', 'TAMANHO_12', 'Aniversário', 1),
(4, 1, 2, 4, 'CIRCULO', 'TAMANHO_15', 'Casamento', 1),
(5, 2, 3, 1, 'CORACAO', 'TAMANHO_17', 'Natal', 1),
(6, 3, 1, 2, 'CIRCULO', 'TAMANHO_5', 'Infantil', 1),
(7, 1, 3, 1, 'CIRCULO', 'TAMANHO_7', 'Carambolo', 1),
(8, 2, 1, 2, 'CORACAO', 'TAMANHO_12', 'Festa Junina', 1);

-- Pedidos Bolo
INSERT INTO teiko.pedido_bolo (endereco_id, bolo_id, usuario_id, observacao, data_previsao_entrega, data_ultima_atualizacao, tipo_entrega, nome_cliente, telefone_cliente, is_ativo) VALUES
(1, 1, 1, 'Sem cobertura de chocolate', '2024-12-15', NOW(), 'ENTREGA', 'João Silva', '11987654321', 1),
(NULL, 2, 1, 'Com tema de casamento', '2024-12-20', NOW(), 'RETIRADA', 'Maria Oliveira', '11912345678', 1),
(1, 3, NULL, 'Com tema de festa junina', '2024-12-25', NOW(), 'ENTREGA', 'Carlos Souza', '11998765432', 1),
(2, 4, 2, 'Bolo de casamento elegante', '2024-12-18', NOW(), 'ENTREGA', 'Ana Costa', '11987654322', 1),
(3, 5, 3, 'Bolo natalino especial', '2024-12-24', NOW(), 'RETIRADA', 'Pedro Santos', '11987654323', 1),
(1, 6, 1, 'Bolo infantil colorido', '2024-12-22', NOW(), 'ENTREGA', 'Lucia Ferreira', '11987654324', 1),
(NULL, 7, 2, 'Carambolo premium', '2024-12-19', NOW(), 'RETIRADA', 'Roberto Lima', '11987654325', 1),
(2, 8, 3, 'Bolo festa junina', '2024-12-21', NOW(), 'ENTREGA', 'Fernanda Alves', '11987654326', 1);

-- Pedidos Fornada
INSERT INTO teiko.pedido_fornada (fornada_da_vez_id, endereco_id, usuario_id, quantidade, data_previsao_entrega, tipo_entrega, nome_cliente, telefone_cliente, is_ativo) VALUES
(1, 1, 1, 10, '2024-12-11', 'ENTREGA', 'Maria Silva', '11999999999', 1),
(1, 2, 2, 15, '2024-12-11', 'ENTREGA', 'João Souza', '11988888888', 1),
(2, 3, 3, 20, '2024-12-13', 'ENTREGA', 'Ana Oliveira', '11977777777', 1);

-- Resumo Pedidos - Setembro 2024 e meses anteriores
-- (dados mockados para demonstração de dashboard)
INSERT INTO teiko.resumo_pedido (status, valor, data_pedido, data_entrega, pedido_fornada_id, pedido_bolo_id, is_ativo) VALUES
('PENDENTE', 100.00, '2024-09-15 10:30:00', '2024-09-20', NULL, 1, 1),
('PAGO', 150.00, '2024-09-14 14:20:00', '2024-09-18', NULL, 2, 1),
('CONCLUIDO', 120.00, '2024-09-13 09:15:00', '2024-09-16', NULL, 3, 1);

-- Adicionais
INSERT INTO teiko.adicional (descricao, is_ativo) VALUES
('Disco ball', 1),
('Desenho', 1),
('Pérolas na finalização', 1),
('Metalizado (Prata ou Dourado)', 1),
('Glitter', 1),
('Cereja (Com ou sem glitter)', 1),
('Laços', 1),
('Escrita', 1),
('Borda (Topo e Base)', 1),
('Lacinhos', 1);

-- Adicionais por Decoração
INSERT INTO teiko.adicional_decoracao (decoracao_id, adicional_id) VALUES
-- VINTAGE
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8),
-- FLORAL
(2, 1), (2, 3), (2, 5), (2, 8), (2, 9),
-- MY CARAMBOLO
(3, 9), (3, 10),
-- SHAG CAKE
(4, 5);

-- =====================================================
-- SCRIPT FINALIZADO
-- =====================================================
