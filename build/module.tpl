
ifndef PACKFFLAGS
@PACKAGE@FFLAGS:=$(FFLAGS)
else
@PACKAGE@FFLAGS:=$(PACKFFLAGS)
endif

ifndef PACKCFLAGS
@PACKAGE@CFLAGS:=$(CFLAGS)
else
@PACKAGE@CFLAGS:=$(PACKCFLAGS)
endif

ifndef PACKCXXFLAGS
@PACKAGE@CXXFLAGS:=$(CXXFLAGS)
else
@PACKAGE@CXXFLAGS:=$(PACKCXXFLAGS)
endif


ifdef DHDR
WITHDICT=YES
else
WITHDICT=
endif

#Extra include,libs etc.
@PACKAGE@INC:=$(patsubst %,-I$(MODDIR)/%,$(EINCLUDE))
@PACKAGE@ELIBS:=$(patsubst %,-l%,$(ELIBS))
@PACKAGE@ELIBSDIR:=$(patsubst %,-L%,$(ELIBSDIR))

#c sources and headers

@PACKAGE@CS:=$(patsubst %,$(MODDIR)/%,$(CSRCS))
@PACKAGE@CH:=$(patsubst %,$(MODDIR)/%,$(CHDRS))

#Fortran sources 
@PACKAGE@FS:=$(patsubst %,$(MODDIR)/%,$(FSRCS))

#c++ sources and header
@PACKAGE@S:=$(patsubst %,$(MODDIR)/%,$(SRCS))
@PACKAGE@H:=$(patsubst %,$(MODDIR)/%,$(HDRS))


# Package Dictionary 

@PACKAGE@DH:=$(MODDIR)/$(DHDR)


#All objects
@PACKAGE@CO:=$(patsubst %,$(MODDIRO)/%, $(CSRCS:.c=.o))
TEMP:=$(FSRCS:.F=.o)
@PACKAGE@FO:=$(patsubst %,$(MODDIRO)/%, $(TEMP:.f=.o))
@PACKAGE@O:= $(patsubst %,$(MODDIRO)/%, $(SRCS:.cxx=.o)) $(@PACKAGE@FO) $(@PACKAGE@CO)

ifdef WITHDICT
  @PACKAGE@DS:=$(MODDIRO)/G__@PACKAGE@.cxx
  @PACKAGE@DO:=$(MODDIRO)/G__@PACKAGE@.o
  @PACKAGE@DDEP:=$(@PACKAGE@DO:.o=.d)
  @PACKAGE@DEP:=$(@PACKAGE@O:.o=.d) $(@PACKAGE@DDEP)
else
  @PACKAGE@DS:=
  @PACKAGE@DO:=
  @PACKAGE@DDEP:=
  @PACKAGE@DEP:=$(@PACKAGE@O:.o=.d)
endif


#The actual library file

@PACKAGE@LIB:=$(LIBPATH)/lib@PACKAGE@.$(SOEXT)

#The actual binary file

@PACKAGE@BIN:=$(BINPATH)/@PACKAGE@


# for using in the main Makefile

ifeq ($(TYPE),lib)
ALLLIBS += $(@PACKAGE@LIB)
BINLIBS += -l@PACKAGE@
else
ALLEXECS += $(@PACKAGE@BIN)
endif

# include all dependency files
INCLUDEFILES +=$(@PACKAGE@DEP)


#local rules

$(@PACKAGE@LIB):$(@PACKAGE@O) $(@PACKAGE@DO) @MODULE@/module.mk
	  @echo "***** Linking library $@ *****"
	  $(SHLD) $(SOFLAGS) $(@PACKAGE@ELIBSDIR) $(@PACKAGE@ELIBS) $(SHLIB)  -o $@ $(@PACKAGE@O) $(@PACKAGE@DO)
 	  
$(@PACKAGE@BIN):$(@PACKAGE@O) $(@PACKAGE@DO) @MODULE@/module.mk
	  @echo "***** Makeing executable $@ *****"
	  $(LD) $(LDFLAGS) $(@PACKAGE@O) $(@PACKAGE@DO) $(BINLIBDIRS)  $(LIBS) $(@PACKAGE@ELIBS) $(EXEFLAGS) -o $@ 

$(@PACKAGE@DS): $(@PACKAGE@H) $(@PACKAGE@DH)
	 @echo "***** Creating $@ *****";	
	 @(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
	 @rootcint -f $@ -c $(CINTFLAGS) $^

$(@PACKAGE@DO): $(@PACKAGE@DS)
		@echo "***** (Re)compiling $< *****";
		@$(CXX) -c $< -o $@ $(CXXFLAGS)

#Different targets for the module

all-@PACKAGE@: $(@PACKAGE@LIB)


depend-@PACKAGE@: $(@PACKAGE@DEP)

# determination of object files
$(MODDIRO)/%.o: $(MODDIR)/%.cxx $(MODDIRO)/%.d 
	@echo "***** (Re)compiling $< *****";
	@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
	$(CXX) -c $(@PACKAGE@INC) $< -o $@ $(@PACKAGE@CXXFLAGS)

$(MODDIRO)/%.o: $(MODDIR)/%.F $(MODDIRO)/%.d 
	@echo "***** (Re)compiling $< *****";
	@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
	$(F77) -c $(@PACKAGE@INC)  $< -o $@ $(@PACKAGE@FFLAGS)

$(MODDIRO)/%.o: $(MODDIR)/%.f $(MODDIRO)/%.d 
	@echo "***** (Re)compiling $< *****";
	@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
	$(F77) -c $(@PACKAGE@INC)  $< -o $@ $(@PACKAGE@FFLAGS)

$(MODDIRO)/%.o: $(MODDIR)/%.c $(MODDIRO)/%.d 
	@echo "***** (Re)compiling $< *****";
	@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
	$(CC) -c $< -o $@ $(@PACKAGE@INC)  $(@PACKAGE@CFLAGS)

$(@PACKAGE@DDEP): $(@PACKAGE@DS)
		@echo "***** Making dependencies for $< *****";
		@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
		@share/alibtool depend "$(@PACKAGE@ELIBSDIR) $(@PACKAGE@INC) $(DEPINC)  $<" > $@

$(MODDIRO)/%.d: $(MODDIRS)/%.cxx
		@echo "***** Making dependencies for $< *****";
		@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
		@share/alibtool depend "$(@PACKAGE@ELIBSDIR) $(@PACKAGE@INC) $(DEPINC)  $<" > $@
$(MODDIRO)/%.d: $(MODDIRS)/%.f
		@echo "***** Making dependencies for $< *****";
		@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
		@share/alibtool dependF "$(@PACKAGE@ELIBSDIR) $(@PACKAGE@INC) $(DEPINC)  $<" > $@
$(MODDIRO)/%.d: $(MODDIRS)/%.F 
		@echo "***** Making dependencies for $< *****";
		@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
		@share/alibtool dependF "$(@PACKAGE@ELIBSDIR) $(@PACKAGE@INC) $(DEPINC)  $<" > $@
$(MODDIRO)/%.d: $(MODDIRS)/%.c 
		@echo "***** Making dependencies for $< *****";
		@(if [ ! -d '$(dir $@)' ]; then echo "***** Making directory $(dir $@) *****"; mkdir -p $(dir $@); fi;)
		@share/alibtool depend "$(@PACKAGE@ELIBSDIR) $(@PACKAGE@INC) $(DEPINC) $<" > $@


#Directory creation

#$(MODDIRO):
#	@echo "***** Making $@ *****"
#	mkdir -p $@
   










