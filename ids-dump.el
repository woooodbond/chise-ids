;;; ids-dump.el --- Dump utility of IDS-* files

;; Copyright (C) 2002 MORIOKA Tomohiko

;; Author: MORIOKA Tomohiko <tomo@kanji.zinbun.kyoto-u.ac.jp>
;; Keywords: IDS, IDC, Ideographs, UCS, Unicode

;; This file is a part of IDS.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'ids)

(defun ids-dump-insert-line (ccs line-spec code)
  (let ((chr (decode-char ccs code))
	id-list)
    (when chr
      (setq id-list (get-char-attribute chr 'ideographic-structure))
      (insert (format line-spec
		      code (decode-builtin-char ccs code)
		      (if id-list
			  (ids-format-list id-list)
			(char-to-string chr)))))))

(defun ids-dump-insert-ccs-ranges (ccs line-spec &rest ranges)
  (let (range code max-code)
    (while ranges
      (setq range (car ranges))
      (cond ((consp range)
	     (setq code (car range)
		   max-code (cdr range))
	     (while (<= code max-code)
	       (ids-dump-insert-line ccs line-spec code)
	       (setq code (1+ code))))
	    ((integerp range)
	     (ids-dump-insert-line ccs line-spec range))
	    (t (error 'wrong-type-argument range)))
      (setq ranges (cdr ranges)))))

(defun ids-dump-insert-daikanwa (start end)
  (let ((i start)
	mdh-alist
	chr sal)
    (map-char-attribute
     (lambda (key val)
       (when (= (length val) 2)
	 (set-alist 'mdh-alist
		    (car val)
		    (put-alist (nth 1 val)
			       key
			       (cdr (assq (car val) mdh-alist)))))
       nil)
     'morohashi-daikanwa)
    (while (<= i end)
      (when (setq chr (decode-char 'ideograph-daikanwa i))
	(insert
	 (format "M-%05d \t%c\t%s\n"
		 i (decode-builtin-char 'ideograph-daikanwa i)
		 (ids-format-list
		  (get-char-attribute chr 'ideographic-structure)))))
      (when (setq sal (assq i mdh-alist))
	(setq sal (cdr sal))
	(when (setq chr (assq 1 sal))
	  (setq chr (cdr chr))
	  (insert
	   (format "M-%05d'\t%c\t%s\n"
		   i chr
		   (ids-format-list
		    (get-char-attribute chr 'ideographic-structure)))))
	(when (setq chr (assq 2 sal))
	  (setq chr (cdr chr))
	  (insert
	   (format "M-%05d\"\t%c\t%s\n"
		   i chr
		   (ids-format-list
		    (get-char-attribute chr 'ideographic-structure)))))
	)
      (setq i (1+ i)))))

(defun ids-dump-insert-daikanwa-hokan ()
  (let (chr sal)
    (map-char-attribute
     (lambda (key val)
       (when (and (eq (car val) 'ho)
		  (null (nthcdr 2 val)))
	 (setq sal (cons (cons (nth 1 val) key) sal)))
       nil)
     'morohashi-daikanwa)
    (setq sal (sort sal (lambda (a b) (< (car a)(car b)))))
    (dolist (cell sal)
      (setq chr (cdr cell))
      (insert
       (format "MH-%04d \t%c\t%s\n"
	       (car cell)
	       chr
	       (ids-format-list
		(get-char-attribute chr 'ideographic-structure)))))))

(defun ids-dump-insert-jis-x0208-1990 ()
  (let ((row 16)
	cell h l code chr)
    (while (<= row 83)
      (setq h (+ row 32))
      (setq cell 1)
      (while (<= cell 94)
	(setq l (+ cell 32))
	(setq chr (make-char 'japanese-jisx0208-1990 h l))
	(insert
	 (format "J90-%02X%02X\t%c\t%s\n"
		 h l
		 (decode-builtin-char 'japanese-jisx0208-1990
				      (logior (lsh h 8) l))
		 (ids-format-list
		  (get-char-attribute chr 'ideographic-structure))))
	(setq cell (1+ cell)))
      (setq row (1+ row)))
    (setq h (+ row 32))
    (setq cell 1)
    (while (<= cell 6)
      (setq l (+ cell 32))
      (setq chr (make-char 'japanese-jisx0208-1990 h l))
      (insert
       (format "J90-%02X%02X\t%c\t%s\n"
	       h l
	       (decode-builtin-char 'japanese-jisx0208-1990
				    (logior (lsh h 8) l))
	       (ids-format-list
		(get-char-attribute chr 'ideographic-structure))))
      (setq cell (1+ cell)))))

(defun ids-dump-range (file path func &rest args)
  (with-temp-buffer
    (let* ((coding-system-for-write 'utf-8))
      (if (file-directory-p path)
	  (setq path (expand-file-name file path)))
      (insert ";; -*- coding: utf-8 -*-\n")
      (apply func args)
      (write-region (point-min)(point-max) path))))

;;;###autoload
(defun ids-dump-ucs-basic (filename)
  (interactive "Fdump IDS-UCS-Basic : ")
  (ids-dump-range "IDS-UCS-Basic.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U+%04X\t%c\t%s\n"
		  '(#x4E00 . #x9FA5)))

;;;###autoload
(defun ids-dump-ucs-ext-a (filename)
  (interactive "Fdump IDS-UCS-Ext-A : ")
  (ids-dump-range "IDS-UCS-Ext-A.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U+%04X\t%c\t%s\n"
		  '(#x3400 . #x4DB5) #xFA1F #xFA23))

;;;###autoload
(defun ids-dump-ucs-compat (filename)
  (interactive "Fdump IDS-UCS-Compat : ")
  (ids-dump-range "IDS-UCS-Compat.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U+%04X\t%c\t%s\n"
		  '(#xF900 . #xFA1E) '(#xFA20 . #xFA22) '(#xFA24 . #xFA2D)))

;;;###autoload
(defun ids-dump-ucs-ext-b-1 (filename)
  (interactive "Fdump IDS-UCS-Ext-B-1 : ")
  (ids-dump-range "IDS-UCS-Ext-B-1.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x20000 . #x21FFF)))

;;;###autoload
(defun ids-dump-ucs-ext-b-2 (filename)
  (interactive "Fdump IDS-UCS-Ext-B-2 : ")
  (ids-dump-range "IDS-UCS-Ext-B-2.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x22000 . #x23FFF)))

;;;###autoload
(defun ids-dump-ucs-ext-b-3 (filename)
  (interactive "Fdump IDS-UCS-Ext-B-3 : ")
  (ids-dump-range "IDS-UCS-Ext-B-3.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x24000 . #x25FFF)))

;;;###autoload
(defun ids-dump-ucs-ext-b-4 (filename)
  (interactive "Fdump IDS-UCS-Ext-B-4 : ")
  (ids-dump-range "IDS-UCS-Ext-B-4.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x26000 . #x27FFF)))

;;;###autoload
(defun ids-dump-ucs-ext-b-5 (filename)
  (interactive "Fdump IDS-UCS-Ext-B-5 : ")
  (ids-dump-range "IDS-UCS-Ext-B-5.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x28000 . #x29FFF)))

;;;###autoload
(defun ids-dump-ucs-ext-b-6 (filename)
  (interactive "Fdump IDS-UCS-Ext-B-6 : ")
  (ids-dump-range "IDS-UCS-Ext-B-6.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x2A000 . #x2A6D6)))

;;;###autoload
(defun ids-dump-ucs-compat-supplement (filename)
  (interactive "Fdump IDS-UCS-Compat-Supplement : ")
  (ids-dump-range "IDS-UCS-Compat-Supplement.txt" filename
		  #'ids-dump-insert-ccs-ranges 'ucs "U-%08X\t%c\t%s\n"
		  '(#x2F800 . #x2FA1D)))

;;;###autoload
(defun ids-dump-daikanwa-01 (filename)
  (interactive "Fdump IDS-Daikanwa-01 : ")
  (ids-dump-range "IDS-Daikanwa-01.txt" filename
		  #'ids-dump-insert-daikanwa 00001 01449))

;;;###autoload
(defun ids-dump-daikanwa-02 (filename)
  (interactive "Fdump IDS-Daikanwa-02 : ")
  (ids-dump-range "IDS-Daikanwa-02.txt" filename
		  #'ids-dump-insert-daikanwa 01450 04674))

;;;###autoload
(defun ids-dump-daikanwa-03 (filename)
  (interactive "Fdump IDS-Daikanwa-03 : ")
  (ids-dump-range "IDS-Daikanwa-03.txt" filename
		  #'ids-dump-insert-daikanwa 04675 07410))

;;;###autoload
(defun ids-dump-daikanwa-04 (filename)
  (interactive "Fdump IDS-Daikanwa-04 : ")
  (ids-dump-range "IDS-Daikanwa-04.txt" filename
		  #'ids-dump-insert-daikanwa 07411 11529))

;;;###autoload
(defun ids-dump-daikanwa-05 (filename)
  (interactive "Fdump IDS-Daikanwa-05 : ")
  (ids-dump-range "IDS-Daikanwa-05.txt" filename
		  #'ids-dump-insert-daikanwa 11530 14414))

;;;###autoload
(defun ids-dump-daikanwa-06 (filename)
  (interactive "Fdump IDS-Daikanwa-06 : ")
  (ids-dump-range "IDS-Daikanwa-06.txt" filename
		  #'ids-dump-insert-daikanwa 14415 17574))

;;;###autoload
(defun ids-dump-daikanwa-07 (filename)
  (interactive "Fdump IDS-Daikanwa-07 : ")
  (ids-dump-range "IDS-Daikanwa-07.txt" filename
		  #'ids-dump-insert-daikanwa 17575 22677))

;;;###autoload
(defun ids-dump-daikanwa-08 (filename)
  (interactive "Fdump IDS-Daikanwa-08 : ")
  (ids-dump-range "IDS-Daikanwa-08.txt" filename
		  #'ids-dump-insert-daikanwa 22678 28107))

;;;###autoload
(defun ids-dump-daikanwa-09 (filename)
  (interactive "Fdump IDS-Daikanwa-09 : ")
  (ids-dump-range "IDS-Daikanwa-09.txt" filename
		  #'ids-dump-insert-daikanwa 28108 32803))

;;;###autoload
(defun ids-dump-daikanwa-10 (filename)
  (interactive "Fdump IDS-Daikanwa-10 : ")
  (ids-dump-range "IDS-Daikanwa-10.txt" filename
		  #'ids-dump-insert-daikanwa 32804 38699))

;;;###autoload
(defun ids-dump-daikanwa-11 (filename)
  (interactive "Fdump IDS-Daikanwa-11 : ")
  (ids-dump-range "IDS-Daikanwa-11.txt" filename
		  #'ids-dump-insert-daikanwa 38700 42209))

;;;###autoload
(defun ids-dump-daikanwa-12 (filename)
  (interactive "Fdump IDS-Daikanwa-12 : ")
  (ids-dump-range "IDS-Daikanwa-12.txt" filename
		  #'ids-dump-insert-daikanwa 42210 48902))

;;;###autoload
(defun ids-dump-daikanwa-index (filename)
  (interactive "Fdump IDS-Daikanwa-dx : ")
  (ids-dump-range "IDS-Daikanwa-dx.txt" filename
		  #'ids-dump-insert-daikanwa 48903 49964))

;;;###autoload
(defun ids-dump-daikanwa-hokan (filename)
  (interactive "Fdump IDS-Daikanwa-ho : ")
  (ids-dump-range "IDS-Daikanwa-ho.txt" filename
		  #'ids-dump-insert-daikanwa-hokan))

;;;###autoload
(defun ids-dump-cbeta (filename)
  (interactive "Fdump IDS-CBETA : ")
  (ids-dump-range "IDS-CBETA.txt" filename
		  #'ids-dump-insert-ccs-ranges
		  'ideograph-cbeta "CB%05d\t%c\t%s\n"
		  '(1 . 13363)))

;;;###autoload
(defun ids-dump-jis-x0208-1990 (filename)
  (interactive "Fdump IDS-JIS-X0208-1990 : ")
  (ids-dump-range "IDS-JIS-X0208-1990.txt" filename
		  #'ids-dump-insert-jis-x0208-1990))

    
;;; @ End.
;;;

(provide 'ids-dump)

;;; ids-dump.el ends here