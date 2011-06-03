#lang racket/base
(require racket/contract
         racket/runtime-path
         racket/port)

;; TODO: use the information in 
;;
;; http://closure-compiler.googlecode.com/svn/trunk/javadoc/index.html
;; and 
;; http://www.ioncannon.net/programming/1447/using-the-google-closure-compiler-in-java/
;;
;; so we don't have to fork java on each compilation request.  We should use a long-running
;; Java process to do this.


(define java-path (find-executable-path "java"))
(define jar-path "compiler.jar")


(provide/contract
 #;[raw-compile-js (input-port? output-port? output-port? . -> . any)]
 [closure-compile ((string?) 
                   ((one-of/c 'whitespace
                              'simple
                              'advanced)) . ->* . string?)])


(define (closure-compile code [compilation-level 'simple])
  (let ([marks (current-continuation-marks)]
        [compiled-code-port (open-output-string)]
        [error-port (open-output-string)])
    (raw-compile-js (open-input-string code)
                    compiled-code-port
                    error-port
                    #:compilation-level compilation-level)
    (let ([compiled (get-output-string compiled-code-port)])
      (cond
        [(maybe-erroneous? compiled)
         (let ([errors (get-output-string error-port)])
           (cond [(string=? errors "")
                  compiled]
                 [else
                  (raise (make-exn:fail (format "closure-compile: ~a" errors)
                                        marks))]))]
        [else
         compiled]))))


(define (maybe-erroneous? result)
  (string=? result ""))


;; Optimization levels.
;; compilation-level->string: symbol -> string
(define (compilation-level->string level)
  (case level
    [(whitespace) "WHITESPACE_ONLY"]
    [(simple) "SIMPLE_OPTIMIZATIONS"]
    [(advanced) "ADVANCED_OPTIMIZATIONS"]))


(define (raw-compile-js ip op err
                        #:compilation-level (compilation-level 'simple))
  (let-values
      ([(subp inp outp errp)
        (subprocess #f #f #f
                    java-path "-jar" jar-path
                    "--compilation_level" (compilation-level->string
                                           compilation-level))])
    (thread (lambda ()
              (copy-port ip outp)
              (close-output-port outp)))
    (thread (lambda ()
              (copy-port inp op)))
    (thread (lambda ()
              (copy-port errp err)))
    (subprocess-wait subp)))

              