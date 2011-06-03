#lang scribble/manual

@title{closure-compile: Compile JavaScript source with the Closure Compiler}

@(require planet/scribble
          planet/version
          planet/resolver
          scribble/eval
          racket/sandbox
          (for-label racket/base)
          (for-label (this-package-in main)))

@(define my-evaluator
   (call-with-trusted-sandbox-configuration 
    (lambda ()
      (parameterize ([sandbox-output 'string]
                     [sandbox-error-output 'string])
        (make-evaluator 
         'racket/base
         #:requires
         (list (resolve-planet-path `(planet , (this-package-version-symbol main)))))))))

@;@(define my-evaluator
@;   (let ([p (resolve-planet-path `(planet , (this-package-version-symbol main)))])
@;     ((make-eval-factory (list `(file ,(path->string p)))))))
    
     
This library exposes the Google
@link["http://closure-compiler.googlecode.com"]{Closure compiler} from
Racket.

The module requires runtime access to Java; 
the value of @racket[(find-executable-path 'java)] should point to a valid Java executable.


@defmodule/this-package[main]
@defproc[(closure-compile [code string?]
                          [compilation-level (or/c 'whitespace 'simple 'advanced) 'simple])
         string?]{
                  @racket[closure-compile] takes the given @racket[code] and passes it to the Closure compiler.  If anything bad happens, it will raise an @racket[exn:fail] and hold the error message in the exception's @racket[exn-message].

                   @examples[#:eval my-evaluator 
                   (closure-compile "alert('hello ' + 'world');")
                   (closure-compile "
                       var f = function(x) { 
                           return x * x; 
                       };
                       alert( f(3) );")]
                   }