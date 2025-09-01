USE lango_db;


CREATE TABLE languages (
  lang_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(20) NOT NULL
) ENGINE = InnoDB;


CREATE TABLE words (
  word_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL,
  description VARCHAR(255),
  lang_id INT NOT NULL,
  CONSTRAINT `fk_words_lang` 
    FOREIGN KEY (lang_id) REFERENCES languages(lang_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT
) ENGINE = InnoDB;


CREATE TABLE phrases (
  phrase_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(255),
  lang_id INT NOT NULL,
  CONSTRAINT `fk_phrases_lang` 
    FOREIGN KEY (lang_id) REFERENCES languages(lang_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT
) ENGINE = InnoDB;


CREATE TABLE tags (
  tag_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(20) NOT NULL,
  description VARCHAR(255)
) ENGINE = InnoDB;


CREATE TABLE words_tags (
  word_tag_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  word_id INT NOT NULL,
  tag_id INT NOT NULL,
  CONSTRAINT `fk_words_wt` 
    FOREIGN KEY (word_id) REFERENCES words(word_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_tags_wt` 
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT
) ENGINE = InnoDB;


CREATE TABLE phrases_tags (
  phrase_tag_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  phrase_id INT NOT NULL,
  tag_id INT NOT NULL,
  CONSTRAINT `fk_phrases_pt` 
    FOREIGN KEY (phrase_id) REFERENCES phrases(phrase_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT,
  CONSTRAINT `fk_tags_pt` 
    FOREIGN KEY (tag_id) REFERENCES tags(tag_id)
    ON DELETE CASCADE
    ON UPDATE RESTRICT
) ENGINE = InnoDB;

