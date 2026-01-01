USE book_rental_management;

CREATE TABLE library (
    library_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    library_name VARCHAR(30) NOT NULL
);

CREATE TABLE bookshelf (
    bookshelf_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    library_id SMALLINT UNSIGNED,
    bookshelf_name VARCHAR(30) NOT NULL,
    CONSTRAINT fk_bookshelf_library_id FOREIGN KEY (library_id) REFERENCES library(library_id)
);

CREATE TABLE layer (
    layer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bookshelf_id INT UNSIGNED,
    layer_name VARCHAR(50) NULL,
    UNIQUE KEY uk_layer (bookshelf_id, layer_name),
    CONSTRAINT fk_layer_bookshelf_pk FOREIGN KEY (bookshelf_id) REFERENCES bookshelf(bookshelf_id)
);

CREATE TABLE block ( -- 하나의 layer에 있는 칸
    block_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    layer_id BIGINT UNSIGNED,
    block_number TINYINT UNSIGNED,
    UNIQUE KEY uk_block (layer_id, block_number),
    CONSTRAINT fk_block_layer_id FOREIGN KEY (layer_id) REFERENCES layer(layer_id)
);

CREATE TABLE book_category (
    book_category_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    book_category_name VARCHAR(50)
);

CREATE TABLE book (
    book_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    block_id BIGINT UNSIGNED NULL,
    carried_at DATE NULL,
    quantity SMALLINT UNSIGNED NULL,
    CONSTRAINT fk_book_block_id FOREIGN KEY (block_id) REFERENCES block(block_id)
);

CREATE TABLE book_basic_list (
    book_id BIGINT UNSIGNED PRIMARY KEY,
    book_title VARCHAR(50) NULL,
    publishing_company VARCHAR(59) NULL,
    book_category_id TINYINT UNSIGNED,
    CONSTRAINT fk_book_basic_list_book_id FOREIGN KEY (book_id) REFERENCES book(book_id),
    CONSTRAINT fk_book_basic_list_book_category_id FOREIGN KEY (book_category_id)
        REFERENCES book_category(book_category_id)
);

CREATE TABLE member (
    member_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    gender ENUM('MALE', 'FEMALE') NULL
);

CREATE TABLE rental (
    rental_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id BIGINT UNSIGNED NOT NULL,
    book_id BIGINT UNSIGNED NOT NULL,
    rental_at DATETIME NOT NULL DEFAULT NOW(),
    return_at DATETIME NULL,
    CONSTRAINT fk_rental_member_id FOREIGN KEY (member_id) REFERENCES member(member_id),
    CONSTRAINT fk_rental_book_id FOREIGN KEY (book_id) REFERENCES book(book_id)
);

CREATE TABLE reservation (
    reservation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reserve_at DATETIME NOT NULL,
    book_id BIGINT UNSIGNED NOT NULL,
    member_id BIGINT UNSIGNED NOT NULL,
    rental_id BIGINT UNSIGNED NULL,
    CONSTRAINT fk_reservation_book_id FOREIGN KEY (book_id) REFERENCES book(book_id),
    CONSTRAINT fk_reservation_member_id FOREIGN KEY (member_id) REFERENCES member(member_id),
    CONSTRAINT fk_reservation_rental_id FOREIGN KEY (rental_id) REFERENCES rental(rental_id)
);


INSERT INTO member (username, password, gender) VALUE ('jewoo15', 'password', 'male');
INSERT INTO library (library_name) VALUE ('동탄 이음터 도서관');
INSERT INTO bookshelf (library_id, bookshelf_name) VALUE (1, '과학/현대');
INSERT INTO layer (bookshelf_id, layer_name) VALUES (1, '지미뉴트론'), (1, '아인슈타인'), (1, '일론머스크');
INSERT INTO block (layer_id, block_number) VALUES (1, 1), (1, 2), (1, 3);
INSERT INTO book (block_id, carried_at, quantity) VALUES (1, '2021-01-01', 10), (2, '2021-01-02', 20);
INSERT INTO rental (member_id, book_id) VALUES (1, 1);
INSERT INTO book_category (book_category_name) VALUE ('여자 과학');
INSERT INTO book_basic_list (book_id, book_title, publishing_company, book_category_id) VALUE (1, '호호 과학', '호호컴퍼니', 1);

SELECT * FROM member;
SELECT * FROM bookshelf;
SELECT * FROM layer;
SELECT * FROM block;
SELECT * FROM book;
SELECT * FROM rental;

EXPLAIN
SELECT m.username, b.book_title, b.publishing_company, r.rental_at
FROM rental r
JOIN member m ON r.member_id = m.member_id
JOIN book_basic_list b ON r.book_id = b.book_id;