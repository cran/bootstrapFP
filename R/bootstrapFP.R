#' Bootstrap algorithms for Finite Population sampling
#' 
#' Bootstrap variance estimation for finite population sampling.
#'
#'
#'
#' @param y vector of sample values
#' @param pik vector of sample first-order inclusion probabilities
#' @param B scalar, number of bootstrap replications
#' @param D scalar, number of replications for the double bootstrap (when applicable)
#' @param method a string indicating the bootstrap method to be used, see Details for more
#' @param design sampling procedure to be used for sample selection.
#'        Either a string indicating the name of the sampling design or a function;
#'        see section "Details" for more information.
#' @param x vector of length N with values of the auxiliary variable for all population units,
#'     only required if method "ppHotDeck" is chosen
#' @param s logical vector of length N, TRUE for units in the sample, FALSE otherwise. 
#'     Alternatively, a vector of length n with the indices of the sample units.
#'     Only required for "ppHotDeck" method.
#' @param distribution required only for \code{method='generalised'}, a string
#'     indicating the distribution to use for the Generalised bootstrap. 
#'     Available options are "uniform", "normal", "exponential" and "lognormal"
#'        
#'
#'
#' @details
#' Argument \code{design} accepts either a string indicating the sampling design
#' to use to draw samples or a function.
#' Accepted designs are "brewer", "tille", "maxEntropy", "poisson",
#' "sampford", "systematic", "randomSystematic".
#' The user may also pass a function as argument; such function should take as input
#' the parameters passed to argument \code{design_pars} and return either a logical
#' vector or a vector of 0 and 1,  where \code{TRUE} or \code{1} indicate sampled
#' units and \code{FALSE} or \code{0} indicate non-sample units.
#' The length of such vector must be equal to the length of \code{x}
#' if \code{units} is not specified, otherwise it must have the same length of \code{units}.
#'
#' \code{method} must be a string indicating the bootstrap method to use.
#' A list of the currently available methods follows, the sampling design they
#' they should be used with is indicated in square brackets.
#' The prefix "pp" indicates a pseudo-population method, the prefix "d"
#' represents a direct method, and the prefix "w" inicates a weights method.
#' For more details on these methods see Mashreghi et al. (2016).
#' 
#' \itemize{
#'     \item "ppGross" [SRSWOR]
#'     \item "ppBooth" [SRSWOR]
#'     \item "ppChaoLo85" [SRSWOR]
#'     \item "ppChaoLo94" [SRSWOR]
#'     \item "ppBickelFreedman" [SRSWOR]
#'     \item "ppSitter" [SRSWOR]
#'     
#'     \item "ppHolmberg" [UPSWOR]
#'     \item "ppChauvet"  [UPSWOR]
#'     \item "ppHotDeck"  [UPSWOR]
#'     
#'     \item "dEfron" [SRSWOR]
#'     \item "dMcCarthySnowden" [SRSWOR]
#'     \item "dRaoWu" [SRSWOR]
#'     \item "dSitter" [SRSWOR]
#'     \item "dAntalTille_UPS" [UPSWOR]
#'     
#'     \item "wRaoWuYue"    [SRSWOR]
#'     \item "wChipperfieldPreston"    [SRSWOR]
#'     \item "wGeneralised" [any]
#' 
#' } 
#'
#'
#' @return 
#' The bootstrap variance of the Horvitz-Thompson estimator.
#'
#'
#' @examples
#'
#' library(bootstrapFP)
#' 
#' ### Generate population data ---
#' N   <- 20; n <- 5
#' x   <- rgamma(N, scale=10, shape=5)
#' y   <- abs( 2*x + 3.7*sqrt(x) * rnorm(N) )
#' pik <- n * x/sum(x)
#' 
#' ### Draw a dummy sample ---
#' s  <- sample(N, n)
#' 
#' ### Estimate bootstrap variance ---
#' bootstrapFP(y = y[s], pik = n/N, B=100, method = "ppSitter")
#' bootstrapFP(y = y[s], pik = pik[s], B=10, method = "ppHolmberg", design = 'brewer')
#' bootstrapFP(y = y[s], pik = pik[s], B=10, D=10, method = "ppChauvet")
#' bootstrapFP(y = y[s], pik = n/N, B=10, method = "dRaoWu")
#' bootstrapFP(y = y[s], pik = n/N, B=10, method = "dSitter")
#' bootstrapFP(y = y[s], pik = pik[s], B=10, method = "dAntalTille_UPS", design='brewer')
#' bootstrapFP(y = y[s], pik = n/N, B=10, method = "wRaoWuYue") 
#' bootstrapFP(y = y[s], pik = n/N, B=10, method = "wChipperfieldPreston")
#' bootstrapFP(y = y[s], pik = pik[s], B=10, method = "wGeneralised", distribution = 'normal')
#'
#'
#'
#' @references
#' Mashreghi Z.; Haziza D.; Léger C., 2016. A survey of bootstrap methods in 
#' finite population sampling. Statistics Surveys 10 1-52.
#' 
#' 
#' 
#' 
#' @importFrom stats var
#' @import sampling 
#'
#'
#' @export




bootstrapFP <- function(y, pik, B, D=1, method, design, x=NULL, s=NULL, distribution='uniform' ){
    
    
    ### Check input ---
    method <- match.arg(method, 
                        c( 'ppGross', 
                           'ppBooth', 
                           'ppChaoLo85', 
                           'ppChaoLo94',
                           'ppBickelFreedman',
                           'ppSitter',
                           'ppHolmberg',
                           'ppChauvet',
                           'ppHotDeck',
                           'dEfron',
                           'dMcCarthySnowden',
                           'dRaoWu',
                           'dSitter',
                           'dAntalTille_UPS',
                           'wRaoWuYue',
                           'wChipperfieldPreston',
                           'wGeneralised'
                        )
    )
    
    
    # Sampling design (only for bootstrap methods for UPS designs)
    if( method %in% c("ppHolmberg", "ppChauvet", "ppHotDeck", "dAntalTille_UPS")){
        
        if( missing(design) ){
            if( identical(method, 'ppChauvet') ){
                design <- 'poisson'
            }
        }
        if( is.character(design) ){
            
            if( !identical(method, 'ppChauvet')){
                design <- match.arg(design, c('brewer',
                                              'tille',
                                              'maxEntropy',
                                              'randomSystematic',
                                              'sampford',
                                              'poisson',
                                              'systematic')
                )
            }else if( identical(method, 'ppChauvet') & !identical(design, 'poisson') ){
                design <- 'poisson'
                message( paste0("Sampling design set to 'Poisson', if your sample has been drawn with ",
                                "a different design, please choose a different bootstrap method!") )
            }
            
            # if( is.character(design)){
            # sampling function
            smplFUN <- switch(EXPR=design,
                              'brewer'           = sampling::UPbrewer,
                              'tille'            = sampling::UPtille,
                              'maxEntropy'       = sampling::UPmaxentropy,
                              'randomSystematic' = sampling::UPrandomsystematic,
                              'sampford'         = sampling::UPsampford,
                              'systematic'       = sampling::UPsystematic,
                              'poisson'          =
                                  function(pik){
                                      ss <- 0
                                      while(ss < 2){
                                          s  <- sampling::UPpoisson( pik )
                                          ss <- sum(s)
                                      }
                                      return( s )
                                  }
            )
        }else if( is.function(design) ){
            smplFUN <- design
        }else stop("Argument design is not well-specified: it should be either a string representing ",
                   "one of the available sampling designs or an object of class function!")
    }   
    

    # Distribution (only for the generalised bootstrap)
    if( identical(method, 'wGeneralised') ){
        distribution <- match.arg(distribution, 
                                  c("uniform", 
                                    "normal", 
                                    "exponential", 
                                    "lognormal"))
    }
    
    
    
    n <- length(y)
    lp <- length(pik)
    
    if( !identical( class(pik), "numeric" ) ){
        stop( "The argument 'pik' should be a numeric vector!")
    }else if( lp < 2 & !(method %in% c('ppGross', 'ppBooth', 'ppChaoLo85', 
                                       'ppChaoLo94', 'ppBickelFreedman',
                                       'ppSitter', 'dEfron', 'dMcCarthySnowden',
                                       'dRaoWu', 'dSitter', 
                                       'wRaoWuYue', 'wChipperfieldPreston') )){
        stop( "The 'pik' vector is too short!" )
    }else if( any(pik<0)  | any(pik>1) ){
        stop( "Some 'pik' values are outside the interval [0, 1]")
    }else if( any(pik %in% c(NA, NaN, Inf)) ){
        stop( "The 'pik' vector contains invalid values (NA, NaN, Inf)" )
    }
    
    if( !(class(y) %in% c("numeric", "integer")) ){
        stop( "The argument 'y' should be a numeric vector!")
    }else if( n < 2 ){
        stop( "The 'y' vector is too short!" )
    }else if( any(y %in% c(NA, NaN, Inf)) ){
        stop( "The 'y' vector contains invalid values (NA, NaN, Inf)" )
    }
    
    if( any(y<0) ){
        message( "Some 'y' values are negative, continuing anyway...")
    }
    
    
    # x and s, only for HotDeck bootstrap
    if( identical(method, 'ppHotDeck') ){
        if(missing(x) | missing(s)) stop("Arguments 'x' and 's' are required for HotDeck bootstrap procedure.")
        if(!identical(length(s), length(x))) stop("Arguments 's' and 'x' should have same length.")
        if(length(s) < n) stop("Arguments 'x' and 's' should have length N>n")
        if(!is.numeric(x)) stop("Argument 'x' should be a numeric vector.")
        if(!is.logical(s)) stop("Argument 's' should be a logical vector.")
        if(sum(s) != n) stop("The number of TRUE values in the 's' argument is not equal to the sample size.")
    }
    
    
    
    ## pseudo-population, srs
    if( method %in% c('ppGross',
                      'ppBooth',
                      'ppChaoLo85', 
                      'ppChaoLo94',
                      'ppBickelFreedman',
                      'ppSitter',
                      'dEfron',
                      'dMcCarthySnowden',
                      'dRaoWu',
                      'dSitter',
                      'wRaoWuYue',
                      'wChipperfieldPreston') ){
        if( length(unique(pik)) > 1 ) stop("pik values should be all equal!")
        N <- (1/pik) * n
    }
    
    
    ### Initialise variables ---
    n <- length(y)
    
    ### Bootstrap ---
    out <- switch(method, 
                  'ppGross' = ppBS_srs(y, N, B, D, method = 'Gross'), 
                  'ppBooth' = ppBS_srs(y, N, B, D, method = 'Booth'), 
                  'ppChaoLo85'= ppBS_srs(y, N, B, D, method = 'ChaoLo85'), 
                  'ppChaoLo94'= ppBS_srs(y, N, B, D, method = 'ChaoLo94'), 
                  'ppBickelFreedman' = ppBS_srs(y, N, B, D, method = 'BickelFreedman'), 
                  'ppSitter'  = ppBS_srs(y, N, B, D, method = 'Sitter'),
                  'ppHolmberg'= ppBS_ups(y, pik, B, D, method = 'Holmberg', smplFUN),
                  'ppChauvet' = ppBS_ups(y, pik, B, D, method = 'Chauvet', smplFUN),
                  'ppHotDeck' = ppBS_ups(y, pik, B, D, method = 'HotDeck', smplFUN, x=x, s=s),
                  'dEfron'    = directBS_srs(y, N, B, method = 'Efron'),
                  'dMcCarthySnowden'= directBS_srs(y, N, B, method = 'McCarthySnowden'),
                  'dRaoWu'          = directBS_srs(y, N, B, method = 'RaoWu'),
                  'dSitter'         = directBS_srs(y, N, B, method = 'Sitter'),
                  'dAntalTille_UPS' = AntalTille2011_ups(y, pik, B, smplFUN, approx_method = 'Hajek'),
                  'wRaoWuYue'            = bootstrap_weights(y, N, B, method = 'RaoWuYue'),
                  'wChipperfieldPreston' = bootstrap_weights(y, N, B, method = 'ChipperfieldPreston'),
                  'wGeneralised' = generalised(y, pik, B, distribution = distribution)
    )
    
    ### Return
    return( out )
    
}