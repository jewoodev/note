DROP TABLE IF EXISTS order_item; -- 다른 예제 충돌 예방
DROP TABLE IF EXISTS order_product;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS orders;

-- 상품 테이블 생성
CREATE TABLE product (
    product_id  BIGINT          NOT NULL, -- 상품id 직접 입력
    name        VARCHAR(100)    NOT NULL,
    price       INT             NOT NULL,
    PRIMARY KEY (product_id)
);

-- 주문 테이블 생성
CREATE TABLE orders (
    order_id    BIGINT NOT NULL, -- 주문id 직접 입력
    order_date  DATE,
    PRIMARY KEY (order_id)
);

-- 연결 테이블(주문-상품) 생성
CREATE TABLE order_product (
    order_product_id    BIGINT  NOT NULL AUTO_INCREMENT,
    order_id            BIGINT  NOT NULL, -- orders 테이블의 FK
    product_id          BIGINT  NOT NULL, -- product 테이블의 FK

    PRIMARY KEY (order_product_id),

    -- 한 주문에 동일한 상품이 중복으로 들어가는 것을 방지
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id),
    CONSTRAINT fk_order_product_orders FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT fk_order_product_product FOREIGN KEY (product_id)
        REFERENCES product (product_id)
);