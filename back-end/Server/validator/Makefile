## include headers and libraries for BOINC
BOINCINCL := -I`pwd`/../sched -I`pwd`/../db -I`pwd`/../lib -I`pwd`/..
BOINCLIBS := -L`pwd`/../lib -L`pwd`/../api -L`pwd`/../sched -lboinc -lboinc_api -lsched -lsched_fcgi -lboinc_fcgi -lfcgi
BOINCCPP := `pwd`/../sched/validator.cpp `pwd`/../sched/validate_util.cpp `pwd`/../sched/validate_util2.cpp
BOINCCPP_TEST := `pwd`/../sched/validator_test.cpp `pwd`/../sched/validate_util.cpp

## include headers and libraries for MySQL
MYSQLINCL := $(shell mysql_config --include)
MYSQLLIBS := $(shell mysql_config --libs)

## compiler etc settings used in default make rules
CXXFLAGS :=             -std=c++11 $(BOINCINCL) $(MYSQLINCL)
LDLIBS :=               $(BOINCLIBS) $(MYSQLLIBS)

all:rboinc_validator rboinc_validator_test

test:rboinc_validator_test

rboinc_validator: main.cpp
	${CXX} main.cpp $(BOINCCPP) ${CXXFLAGS} ${CPPFLAGS} ${LDLIBS} -o rboinc_validator

rboinc_validator_test:main.cpp
	${CXX} main.cpp $(BOINCCPP_TEST) -g ${CXXFLAGS} ${CPPFLAGS} ${LDLIBS} -o rboinc_validator_test

clean:
	rm rboinc_validator rboinc_validator_test
