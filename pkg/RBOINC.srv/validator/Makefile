## comment this out if you need a different version of R,
## and set set R_HOME accordingly as an environment variable
R_HOME :=               $(shell R RHOME)

## include headers and libraries for R
RCPPFLAGS :=            $(shell $(R_HOME)/bin/R CMD config --cppflags)
RLDFLAGS :=             $(shell $(R_HOME)/bin/R CMD config --ldflags)
RBLAS :=                $(shell $(R_HOME)/bin/R CMD config BLAS_LIBS)
RLAPACK :=              $(shell $(R_HOME)/bin/R CMD config LAPACK_LIBS)

## include headers and libraries for Rcpp interface classes
## note that RCPPLIBS will be empty with Rcpp (>= 0.11.0) and can be omitted
RCPPINCL :=             $(shell echo 'Rcpp:::CxxFlags()' | $(R_HOME)/bin/R --vanilla --slave)
RCPPLIBS :=             $(shell echo 'Rcpp:::LdFlags()'  | $(R_HOME)/bin/R --vanilla --slave)


## include headers and libraries for RInside embedding classes
RINSIDEINCL :=          $(shell echo 'RInside:::CxxFlags()' | $(R_HOME)/bin/R --vanilla --slave)
RINSIDELIBS :=          $(shell echo 'RInside:::LdFlags()'  | $(R_HOME)/bin/R --vanilla --slave)

## include headers and libraries for BOINC
BOINCINCL := -I`pwd`/../sched -I`pwd`/../db -I`pwd`/../lib -I`pwd`/..
BOINCLIBS := -L`pwd`/../lib -L`pwd`/../api -L`pwd`/../sched -lboinc -lboinc_api -lsched -lsched_fcgi -lboinc_fcgi -lfcgi
BOINCCPP := `pwd`/../sched/validator.cpp `pwd`/../sched/validate_util.cpp `pwd`/../sched/validate_util2.cpp
BOINCCPP_TEST := `pwd`/../sched/validator_test.cpp `pwd`/../sched/validate_util.cpp

## include headers and libraries for MySQL
MYSQLINCL := $(shell mysql_config --include)
MYSQLLIBS := $(shell mysql_config --libs)

## compiler etc settings used in default make rules
CXX :=                  $(shell $(R_HOME)/bin/R CMD config CXX)
CPPFLAGS :=             -Wall $(shell $(R_HOME)/bin/R CMD config CPPFLAGS)
CXXFLAGS :=             $(RCPPFLAGS) $(RCPPINCL) $(RINSIDEINCL) $(BOINCINCL) $(MYSQLINCL) $(shell $(R_HOME)/bin/R CMD config CXXFLAGS | awk '{gsub(/\-g/,"")}1')
LDLIBS :=               $(RLDFLAGS) $(RRPATH) $(RBLAS) $(RLAPACK) $(RCPPLIBS) $(RINSIDELIBS) $(BOINCLIBS) $(MYSQLLIBS)

all:rboinc_validator rboinc_validator_test

test:rboinc_validator_test

rboinc_validator: main.cpp
	${CXX} main.cpp $(BOINCCPP) ${CXXFLAGS} ${CPPFLAGS} ${LDLIBS} -o rboinc_validator

rboinc_validator_test:main.cpp
	${CXX} main.cpp $(BOINCCPP_TEST) -g ${CXXFLAGS} ${CPPFLAGS} ${LDLIBS} -o rboinc_validator_test

clean:
	rm rboinc_validator rboinc_validator_test
