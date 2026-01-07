USE book_rental_management;

CREATE TABLE library (
    library_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    library_name VARCHAR(30) NOT NULL,
    PRIMARY KEY (library_id)
);

CREATE TABLE bookshelf (
    library_id SMALLINT UNSIGNED NOT NULL,
    bookshelf_id SMALLINT UNSIGNED NOT NULL,
    bookshelf_name VARCHAR(30) NOT NULL,
    PRIMARY KEY (library_id, bookshelf_id),
    CONSTRAINT fk_bookshelf_library FOREIGN KEY (library_id) REFERENCES library(library_id)
);

CREATE TABLE layer (
    library_id SMALLINT UNSIGNED NOT NULL,
    bookshelf_id SMALLINT UNSIGNED NOT NULL,
    layer_id TINYINT UNSIGNED NOT NULL,
    layer_name VARCHAR(50) NULL,
    PRIMARY KEY (library_id, bookshelf_id, layer_id),
    CONSTRAINT fk_layer_bookshelf FOREIGN KEY (library_id, bookshelf_id)
        REFERENCES bookshelf(library_id, bookshelf_id)
);

CREATE TABLE block ( -- 하나의 layer에 있는 칸
    library_id SMALLINT UNSIGNED NOT NULL,
    bookshelf_id SMALLINT UNSIGNED NOT NULL,
    layer_id TINYINT UNSIGNED NOT NULL,
    block_id TINYINT UNSIGNED NOT NULL,
    block_number TINYINT UNSIGNED,
    PRIMARY KEY (library_id, bookshelf_id, layer_id, block_id),
    CONSTRAINT fk_block_layer FOREIGN KEY (library_id, bookshelf_id, layer_id)
        REFERENCES layer(library_id, bookshelf_id, layer_id)
);

CREATE TABLE book (
    book_id BIGINT UNSIGNED NOT NULL,
    library_id SMALLINT UNSIGNED NOT NULL,
    bookshelf_id SMALLINT UNSIGNED NOT NULL,
    layer_id TINYINT UNSIGNED NOT NULL,
    block_id TINYINT UNSIGNED NOT NULL,
    carried_at DATE NULL,
    quantity SMALLINT UNSIGNED NULL,
    PRIMARY KEY (book_id),
    UNIQUE KEY uk_book (library_id, bookshelf_id, layer_id, block_id),
    CONSTRAINT fk_book_block FOREIGN KEY (library_id, bookshelf_id, layer_id, block_id)
        REFERENCES block(library_id, bookshelf_id, layer_id, block_id)
);

CREATE TABLE book_category (
   book_category_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
   book_category_name VARCHAR(50)
);

CREATE TABLE book_basic_list (
    book_id BIGINT UNSIGNED NOT NULL,
    book_category_id TINYINT UNSIGNED NOT NULL,
    book_title VARCHAR(50) NULL,
    publishing_company VARCHAR(59) NULL,
    PRIMARY KEY (book_id),
    CONSTRAINT fk_book_basic_list_book FOREIGN KEY (book_id)
        REFERENCES book(book_id),
    CONSTRAINT fk_book_basic_list_book_category FOREIGN KEY (book_category_id)
        REFERENCES book_category(book_category_id)
);

CREATE TABLE member (
    member_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(100) NOT NULL,
    gender ENUM('MALE', 'FEMALE') NULL,
    PRIMARY KEY (member_id)
);

CREATE TABLE reservation (
    reservation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    reserve_at DATETIME NOT NULL,
    book_id BIGINT UNSIGNED NOT NULL,
    member_id BIGINT UNSIGNED NOT NULL,
    PRIMARY KEY (reservation_id),
    CONSTRAINT fk_reservation_book_id FOREIGN KEY (book_id)
        REFERENCES book(book_id),
    CONSTRAINT fk_reservation_member_id FOREIGN KEY (member_id)
        REFERENCES member(member_id)
);

CREATE TABLE rental (
    rental_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    member_id BIGINT UNSIGNED NOT NULL,
    book_id BIGINT UNSIGNED NOT NULL,
    reservation_id BIGINT UNSIGNED NULL,
    rental_at DATETIME NOT NULL DEFAULT NOW(),
    return_at DATETIME NULL,
    PRIMARY KEY (rental_id),
    CONSTRAINT fk_rental_member FOREIGN KEY (member_id)
        REFERENCES member(member_id),
    CONSTRAINT fk_rental_book FOREIGN KEY (book_id)
        REFERENCES book(book_id),
    CONSTRAINT fk_rental_reservation FOREIGN KEY (reservation_id)
        REFERENCES reservation(reservation_id)
);


INSERT INTO member (username, password, gender) VALUE ('jewoo15', 'password', 'male');

INSERT INTO library (library_name) VALUE ('동탄 이음터 도서관');

INSERT INTO bookshelf (library_id, bookshelf_id, bookshelf_name) VALUE (1, 1,'과학/현대');

INSERT INTO layer (library_id, bookshelf_id, layer_id, layer_name)
VALUES
    (1, 1, 1, '지미뉴트론'),
    (1,1, 2, '아인슈타인'),
    (1, 1, 3, '일론머스크');

# INSERT INTO block (library_id, bookshelf_id, layer_id, block_id, block_number)
# VALUES
#     (1, 1), (1, 2), (1, 3);
# INSERT INTO book (block_id, carried_at, quantity) VALUES (1, '2021-01-01', 10), (2, '2021-01-02', 20);
# INSERT INTO rental (member_id, book_id) VALUES (1, 1);
# INSERT INTO book_category (book_category_name) VALUE ('여자 과학');
# INSERT INTO book_basic_list (book_id, book_title, publishing_company, book_category_id) VALUE (1, '호호 과학', '호호컴퍼니', 1);
#
# SELECT * FROM member;
# SELECT * FROM bookshelf;
# SELECT * FROM layer;
# SELECT * FROM block;
# SELECT * FROM book;
# SELECT * FROM rental;
#
# EXPLAIN
# SELECT m.username, b.book_title, b.publishing_company, r.rental_at
# FROM rental r
# JOIN member m ON r.member_id = m.member_id
# JOIN book_basic_list b ON r.book_id = b.book_id;
