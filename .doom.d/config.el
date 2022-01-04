;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Tobin Stultiens"
      user-mail-address "tobin.stultiens@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
(setq auth-sources '("~/.config/emacs/.authinfo"))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(setq-hook! 'vue-mode-hook +format-with 'prettier-prettify)

(setq vue-indent-level 2)
(setq mmm-js-mode-enter-hook (lambda () (setq syntax-ppss-table nil)))
(setq mmm-typescript-mode-enter-hook (lambda () (setq syntax-ppss-table nil)))

;(require 'eglot)
;(require 'web-mode)
;(define-derived-mode genehack-vue-mode web-mode "ghVue"
;  "A major mode derived from web-mode, for editing .vue files with LSP support.")
;(add-to-list 'auto-mode-alist '("\\.vue\\'" . genehack-vue-mode))
;(add-hook 'genehack-vue-mode-hook #'eglot-ensure)
;(add-to-list 'eglot-server-programs '(genehack-vue-mode "vls"))

;; Format on save eslint
(eval-after-load 'js2-mode
  '(add-hook 'js2-mode-hook (lambda () (add-hook 'after-save-hook 'prettier-eslint nil t))))
  '(add-hook 'react-mode-hook (lambda () (add-hook 'after-save-hook 'prettier-eslint nil t)))
  '(add-hook 'genehack-vue-mode-hook (lambda () (add-hook 'after-save-hook 'prettier-eslint nil t)))

(setq org-latex-packages-alist '("\\hypersetup{colorlinks=true,linkcolor=blue}"))

(setq org-publish-use-timestamps-flag nil)
(setq org-export-with-broken-links t)
(setq org-publish-project-alist
      '(("cooking"
         :base-directory "~/org/cooking/"
         :base-extension "org"
         :publishing-directory "~/org/cooking/html/"
         :recursive t
         :publishing-function org-html-publish-to-html
         :headline-levels 4
         :auto-preamble t)
        ("org-static"
         :base-directory "~/org/website"
         :base-extension "pdf\\|js\\|jpg\\|png\\|gif"
         :publishing-directory "~/publich_html/"
         :recurcive t
         :publishing-function org-publish-attachment)
        ))
