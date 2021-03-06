;;; pycarddavel.el --- Integrate pycarddav -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Version: 0.1
;; GIT: https://github.com/DamienCassou/pycarddavel
;; Package-Requires: ((helm "1.7.0") (emacs "24.0"))
;; Created: 07 Jun 2015
;; Keywords: helm pyccarddav carddav message mu4e contacts

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Write carddav contact names and email addresses as a
;; comma-separated text (call `pycarddavel-search-with-helm` to start
;; the process).
;;
;;; Code:


(require 'cl-lib)
(require 'eieio)
(require 'helm)

(defun pycarddavel-get-contacts-buffer ()
  "Put all pycarddav contacts in the returned buffer."
  (let ((buffer (get-buffer-create "*pycarddavel-contacts*")))
    (with-current-buffer buffer
      (erase-buffer)
      (call-process
       "pc_query"
       nil ;; input file
       (list buffer nil) ;; output to buffer, discard error
       nil ;; don't redisplay
       "-m") ;; 1st arg to pc_query: prints email addresses
      (goto-char (point-min))
      (kill-whole-line 1))
    buffer))

(defun pycarddavel-get-contact-from-line (line)
  "Return a carddav contact read from LINE.

The line must start with something like:
some@email.com	Some Name

The returned contact is of the form
 (:name \"Some Name\" :mail \"some@email.com\")"
  (when (string-match "\\(.*?\\)\t\\(.*?\\)\t" line)
    (list :name (match-string 2 line) :mail (match-string 1 line))))

(defun pycarddavel--helm-source-init ()
  "Initialize helm candidate buffer."
  (helm-candidate-buffer (pycarddavel-get-contacts-buffer)))

(defun pycarddavel--helm-source-select-action (candidate)
  "Print selected contacts as comma-separated text.
CANDIDATE is ignored."
  (ignore candidate)
  (cl-loop for candidate in (helm-marked-candidates)
           do (let ((contact (pycarddavel-get-contact-from-line candidate)))
                (insert (format "\"%s\" <%s>, "
                                (plist-get contact :name)
                                (plist-get contact :mail))))))

(defclass pycarddavel--helm-source (helm-source-in-buffer)
  ((init :initform #'pycarddavel--helm-source-init)
   (nohighlight :initform t)
   (action :initform (helm-make-actions
                      "Select" #'pycarddavel--helm-source-select-action))
   (requires-pattern :initform 0)))

;;;#autoload
(defun pycarddavel-search-with-helm ()
  "Start helm to select your contacts from a list."
  (interactive)
  (helm
   :prompt "contacts: "
   :sources (helm-make-source "Contacts" 'pycarddavel--helm-source)))

(provide 'pycarddavel)

;;; pycarddavel.el ends here

;;  LocalWords:  pycarddav carddav
