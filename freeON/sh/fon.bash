#!/bin/bash
#
#	A driver program to run freeON
#
#	This program is intended to facilitate use of FreeON in a variety
# of scenarios.
#
#	The general approach consists on relying on predefined calculations
# containing safe parameter combinations and stored in a ".pre" file, either
# in a global template directory, or on the current directory. These files
# are just normal FreeON input file without the coordinates.
#
#	To run a calculation you must provide at least a molecule file with
# the coordinates in either XYZ or MOL2 format, and a predefined calculation
# options file. The driver will combine them to create an input file, place
# it in a subdirectory and run the calculation inside the subdirectory.
#
#	There are two ways to provide this information: one is to do so
# in environment variables (intended for batch submission):
#		$f	the coordinates file in XYZ or MOL2 format
#		$c	the computation to run (a predefined configuration
#			in a .pre file, i.e. a normal FreeON input file
#			without coordinates).
#
#	The other is using the command line. You may run this driver
# program with options "-h" or "--help" for more information.
#
#	The command line approach also allows you to fine tune the calculation
# by modifying specific parameters, such as charge, multiplicity, etc... This
# allows you to have only one general configuration file that may be applied
# to many different variants of the same problem.
#
#	For instance, you might have an 'optimize.pre' file for generic
# optimization, and then reuse it with different ionization states by 
# modifying the default neutral state to various charged states.
#
#	When a predefined calculation is run, the driver will generate the
# results in a directory named after the molecule name and the calculation
# e.g. H2O_optimization
#
#	When you run a modified (through command line switch options)
# predefined calculation, the output will be generated in a directory named
# after the molecule name, the calculation, and the modified parameters
# e.g. SO4H_optimization_q=-1
#
#	As a general rule, the driver will try to guess reasonable, safe
# options for your selected modifications (e.g. adapting multiplicity to
# ionization state), but you should check the output and if there are
# errors or problems (like convergence issues) manually modify the
# calculation using your best chemical intuition, knowledge and experience.
#
#
#	(C) Jose R Valverde, 2011-2015
#

#file=${f:-$1}
#c=${c:-$2}

export ME=`basename $0`

export MONDO_SCRATCH="."
export MONDO_HOME=~/contrib/freeON/
export MONDO_EXEC=$MONDO_HOME/bin
export BASIS_SETS=$MONDO_HOME/share/freeon/BasisSets

export FREEON_SCRATCH="."
export FREEON_HOME=$MONDO_HOME
export FREEON_EXEC=$MONDO_HOME/bin
export FREEON_BASISSETS=$FREEON_HOME/share/freeon/BasisSets

export FREEON_TEMPLATES=$FREEON_HOME/templates

export PATH=$FREEON_HOME/bin:$PATH
export LD_LIBRARY_PATH=$FREEON_HOME/lib:$LD_LIBRARY_PATH

babel=`which babel`

# declare an array of element symbols (i.e. the symbols in the periodic table)
declare -a ELEMS=(\
"H"                                                                                                                                                           "HE" \
"LI" "BE"                                                                                                                         "B"   "C"  "N"   "O"  "F"   "NE" \ 
"NA" "MG"                                                                                                                         "AL"  "SI" "P"   "S"  "CL"  "AR" \
"K"  "CA" "SC"                                                                       "TI" "V"  "CR" "MN" "FE" "CO" "NI" "CU" "ZN" "GA"  "GE" "AS"  "SE" "BR"  "KR" \
"RB" "SR" "Y"                                                                        "ZR" "NB" "MO" "TC" "RU" "RH" "PD" "AG" "CD" "IN"  "SN" "SB"  "TE" "I"   "XE" \
"CS" "BA" "LA" "CE" "PR" "ND" "PM" "SM" "EU" "GD" "TB" "DY" "HO" "ER" "TM" "YB" "LU" "HF" "TA" "W"  "RE" "OS" "IR" "PT" "AU" "HG" "TL"  "PB" "BI"  "PO" "AT"  "RN" \
"FR" "RA" "AC" "TH" "PA" "U"  "NP" "PU" "AM" "CM" "BK" "CF" "ES" "FM" "MD" "NO" "LR" "RF" "DB" "SG" "BH" "HS" "MT" "DS" "RG" "CN" "UUT" "FL" "UUP" "LV" "UUS" "UUO" )

export ELEMS

# NAME
# 	banner - print large banner
#
# SYNOPSIS
#	banner text
#
# DESCRIPTION
#	banner prints out the first 10 characters of "text" in large letters
#
function banner {
    #
    # Taken from http://stackoverflow.com/questions/652517/whats-the-deal-with-the-banner-command
    #
    #	Msg by jlliagre
    #		Apr 15 '12 at 11:52
    #
    # ### JR ###
    #	Input:	A text up to 10 letter wide
    # This has been included because banner(1) is no longer a standard
    # tool in many Linux systems. This way we avoid having a dependency
    # that might not be met.
    # It is often installed through package 'sysvbanner'
    #	npm has an ascii-banner tool (npm -g install ascii-banner)
    # Other alternatives are toilet(1) and figlet(1)

    typeset A=$((1<<0))
    typeset B=$((1<<1))
    typeset C=$((1<<2))
    typeset D=$((1<<3))
    typeset E=$((1<<4))
    typeset F=$((1<<5))
    typeset G=$((1<<6))
    typeset H=$((1<<7))

    function outLine
    {
      typeset r=0 scan
      for scan
      do
        typeset l=${#scan}
        typeset line=0
        for ((p=0; p<l; p++))
        do
          line="$((line+${scan:$p:1}))"
        done
        for ((column=0; column<8; column++))
          do
            [[ $((line & (1<<column))) == 0 ]] && n=" " || n="#"
            raw[r]="${raw[r]}$n"
          done
          r=$((r+1))
        done
    }

    function outChar
    {
        case "$1" in
        (" ") outLine "" "" "" "" "" "" "" "" ;;
        ("0") outLine "BCDEF" "AFG" "AEG" "ADG" "ACG" "ABG" "BCDEF" "" ;;
        ("1") outLine "F" "EF" "F" "F" "F" "F" "F" "" ;;
        ("2") outLine "BCDEF" "AG" "G" "CDEF" "B" "A" "ABCDEFG" "" ;;
        ("3") outLine "BCDEF" "AG" "G" "CDEF" "G" "AG" "BCDEF" "" ;;
        ("4") outLine "AF" "AF" "AF" "BCDEFG" "F" "F" "F" "" ;;
        ("5") outLine "ABCDEFG" "A" "A" "ABCDEF" "G" "AG" "BCDEF" "" ;;
        ("6") outLine "BCDEF" "A" "A" "BCDEF" "AG" "AG" "BCDEF" "" ;;
        ("7") outLine "BCDEFG" "G" "F" "E" "D" "C" "B" "" ;;
        ("8") outLine "BCDEF" "AG" "AG" "BCDEF" "AG" "AG" "BCDEF" "" ;;
        ("9") outLine "BCDEF" "AG" "AG" "BCDEF" "G" "G" "BCDEF" "" ;;
        ("a") outLine "" "" "BCDE" "F" "BCDEF" "AF" "BCDEG" "" ;;
        ("b") outLine "B" "B" "BCDEF" "BG" "BG" "BG" "ACDEF" "" ;;
        ("c") outLine "" "" "CDE" "BF" "A" "BF" "CDE" "" ;;
        ("d") outLine "F" "F" "BCDEF" "AF" "AF" "AF" "BCDEG" "" ;;
        ("e") outLine "" "" "BCDE" "AF" "ABCDEF" "A" "BCDE" "" ;;
        ("f") outLine "CDE" "B" "B" "ABCD" "B" "B" "B" "" ;;
        ("g") outLine "" "" "BCDEG" "AF" "AF" "BCDE" "F" "BCDE" ;;
        ("h") outLine "B" "B" "BCDE" "BF" "BF" "BF" "ABF" "" ;;
        ("i") outLine "C" "" "BC" "C" "C" "C" "ABCDE" "" ;;
        ("j") outLine "D" "" "CD" "D" "D" "D" "AD" "BC" ;;
        ("k") outLine "B" "BE" "BD" "BC" "BD" "BE" "ABEF" "" ;;
        ("l") outLine "AB" "B" "B" "B" "B" "B" "ABC" "" ;;
        ("m") outLine "" "" "ACEF" "ABDG" "ADG" "ADG" "ADG" "" ;;
        ("n") outLine "" "" "BDE" "BCF" "BF" "BF" "BF" "" ;;
        ("o") outLine "" "" "BCDE" "AF" "AF" "AF" "BCDE" "" ;;
        ("p") outLine "" "" "ABCDE" "BF" "BF" "BCDE" "B" "AB" ;;
        ("q") outLine "" "" "BCDEG" "AF" "AF" "BCDE" "F" "FG" ;;
        ("r") outLine "" "" "ABDE" "BCF" "B" "B" "AB" "" ;;
        ("s") outLine "" "" "BCDE" "A" "BCDE" "F" "ABCDE" "" ;;
        ("t") outLine "C" "C" "ABCDE" "C" "C" "C" "DE" "" ;;
        ("u") outLine "" "" "AF" "AF" "AF" "AF" "BCDEG" "" ;;
        ("v") outLine "" "" "AG" "BF" "BF" "CE" "D" "" ;;
        ("w") outLine "" "" "AG" "AG" "ADG" "ADG" "BCEF" "" ;;
        ("x") outLine "" "" "AF" "BE" "CD" "BE" "AF" "" ;;
        ("y") outLine "" "" "BF" "BF" "BF" "CDE" "E" "BCD" ;;
        ("z") outLine "" "" "ABCDEF" "E" "D" "C" "BCDEFG" "" ;;
        ("A") outLine "D" "CE" "BF" "AG" "ABCDEFG" "AG" "AG" "" ;;
        ("B") outLine "ABCDE" "AF" "AF" "ABCDE" "AF" "AF" "ABCDE" "" ;;
        ("C") outLine "CDE" "BF" "A" "A" "A" "BF" "CDE" "" ;;
        ("D") outLine "ABCD" "AE" "AF" "AF" "AF" "AE" "ABCD" "" ;;
        ("E") outLine "ABCDEF" "A" "A" "ABCDE" "A" "A" "ABCDEF" "" ;;
        ("F") outLine "ABCDEF" "A" "A" "ABCDE" "A" "A" "A" "" ;;
        ("G") outLine "CDE" "BF" "A" "A" "AEFG" "BFG" "CDEG" "" ;;
        ("H") outLine "AG" "AG" "AG" "ABCDEFG" "AG" "AG" "AG" "" ;;
        ("I") outLine "ABCDE" "C" "C" "C" "C" "C" "ABCDE" "" ;;
        ("J") outLine "BCDEF" "D" "D" "D" "D" "BD" "C" "" ;;
        ("K") outLine "AF" "AE" "AD" "ABC" "AD" "AE" "AF" "" ;;
        ("L") outLine "A" "A" "A" "A" "A" "A" "ABCDEF" "" ;;
        ("M") outLine "ABFG" "ACEG" "ADG" "AG" "AG" "AG" "AG" "" ;;
        ("N") outLine "AG" "ABG" "ACG" "ADG" "AEG" "AFG" "AG" "" ;;
        ("O") outLine "CDE" "BF" "AG" "AG" "AG" "BF" "CDE" "" ;;
        ("P") outLine "ABCDE" "AF" "AF" "ABCDE" "A" "A" "A" "" ;;
        ("Q") outLine "CDE" "BF" "AG" "AG" "ACG" "BDF" "CDE" "FG" ;;
        ("R") outLine "ABCD" "AE" "AE" "ABCD" "AE" "AF" "AF" "" ;;
        ("S") outLine "CDE" "BF" "C" "D" "E" "BF" "CDE" "" ;;
        ("T") outLine "ABCDEFG" "D" "D" "D" "D" "D" "D" "" ;;
        ("U") outLine "AG" "AG" "AG" "AG" "AG" "BF" "CDE" "" ;;
        ("V") outLine "AG" "AG" "BF" "BF" "CE" "CE" "D" "" ;;
        ("W") outLine "AG" "AG" "AG" "AG" "ADG" "ACEG" "BF" "" ;;
        ("X") outLine "AG" "AG" "BF" "CDE" "BF" "AG" "AG" "" ;;
        ("Y") outLine "AG" "AG" "BF" "CE" "D" "D" "D" "" ;;
        ("Z") outLine "ABCDEFG" "F" "E" "D" "C" "B" "ABCDEFG" "" ;;
        (".") outLine "" "" "" "" "" "" "D" "" ;;
        (",") outLine "" "" "" "" "" "E" "E" "D" ;;
        (":") outLine "" "" "" "" "D" "" "D" "" ;;
        ("!") outLine "D" "D" "D" "D" "D" "" "D" "" ;;
        ("/") outLine "G" "F" "E" "D" "C" "B" "A" "" ;;
        ("\\") outLine "A" "B" "C" "D" "E" "F" "G" "" ;;
        ("|") outLine "D" "D" "D" "D" "D" "D" "D" "D" ;;
        ("+") outLine "" "D" "D" "BCDEF" "D" "D" "" "" ;;
        ("-") outLine "" "" "" "BCDEF" "" "" "" "" ;;
        ("*") outLine "" "BDF" "CDE" "D" "CDE" "BDF" "" "" ;;
        ("=") outLine "" "" "BCDEF" "" "BCDEF" "" "" "" ;;
        (*) outLine "ABCDEFGH" "AH" "AH" "AH" "AH" "AH" "AH" "ABCDEFGH" ;;
        esac
    }

    function outArg
    {
      typeset l=${#1} c r
      for ((c=0; c<l; c++))
      do
        outChar "${1:$c:1}"
      done
      echo
      for ((r=0; r<8; r++))
      do
        printf "%-*.*s\n" "${COLUMNS:-80}" "${COLUMNS:-80}" "${raw[r]}"
        raw[r]=""
      done
    }

    for i
    do
      outArg "$i"
      echo
    done
}

# NAME
#    is_int()
#
# SYNOPSIS
#    usage: if is_int value ; then ... else .. fi
#
# DESCRIPTION
#    Test if value is an integer (positive, negative or zero)
#
#    (c) José R. Valverde
#
function is_int() {
#    return $(test "$@" -eq "$@" > /dev/null 2>&1)
#    if [[ $@ == [0-9]* ]] ; return 1 ; fi
    if [[ $@ =~ ^-?\+?[0-9]+$ ]] ; then return 1 ; fi
}


# NAME
#	strindex - lookup in a string a substring
#
# SYNOPSIS
#	strindex "a large string" "string"
#
# DESCRIPTION
#	strindex returns the position of the substring in the large
#	string, if found, or -1 if it is not present
#
#
#    (c) José R. Valverde
#
function strindex() { 
  # return position of $2 in $1, or -1 if not found
  x="${1%%$2*}"
  [[ $x = $1 ]] && echo -1 || echo ${#x}
}


# NAME
#    calc_e()
#
# SYNOPSIS
#    usage: nelec=calc_e moleculefile charge
#
# DESCRIPTION
#    Calculate the total number of electrons in a molecule contained
# in an XYZ file, taking into account the specified charge of the molecule
#
#    (c) José R. Valverde
#
function calc_e() {
    # file must be an XYZ file
    local f=$1
    local q=${2:-'0'}	# charge of the molecule
    
    # list only basis sets valid with support for all atoms in
    # the molecule to analyze
    #
    # get list of atoms
    local nelec=0
    while read atom ; do
        # convert atom names to numbers
        for (( i = 0; i < ${#ELEMS[@]}; i++ )); do
           if [ "${ELEMS[$i]}" = "$atom" ]; then
               nelec=$(($nelec + $i + 1))
               #echo "$atom $(($i + 1)) $nelec"
               break
           fi
        done        
    done < <(tail -n +3 $f | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')
    #### JR ###
    # this may be non-obvious:
    #	If charge is positive, we assume we have lost electrons
    #   If charge is negative, we assume we have lost protons (or acquired e-)
    nelec=$(($nelec - $q))
    echo $nelec
    return $nelec
}


# NAME
#    list_parameter_files()
#
# SYNOPSIS
#    list_parameter_files ; exit
#
# DESCRIPTION
#    List all available parameter files, both in the system default
#    directory and in the current directory. Paramater files must
#    be valid FreeON configuration files witrhout molecule coordinates
#    and with a name ending in a .pre extension
#
#    (c) José R. Valverde
#
#
list_parameter_files()
{
    local templ i
    # using a list of space separated values "1 2 3"
    #   we'll get an error if there are no templates
    #    (we must redirect stderr to get rid of the error message)
    if tmpl=`/bin/ls $FREEON_TEMPLATES/*.pre 2>/dev/null` ; then
        echo "List of available computations"
        echo "  in $FREEON_TEMPLATES"
        for i in $tmpl ; do
            if [ -f "$i" ] ; then
	        echo -e "    " `basename $i .pre` "\t"
	        grep '^#JR:' $i | sed -e 's/#JR:/        /g'
	        grep '^#DESC:' $i | sed -e 's/#DESC:/        /g'
	        echo ''
            fi
        done
    else
        echo "There are no computations in $FREEON_TEMPLATES"
    fi

    # (we must redirect stderr to get rid of the error message)
    if tmpl=`/bin/ls ./*.pre 2>/dev/null` ; then
        echo "List of available computations"
        echo "  in current directory (*.pre files)"
        for i in $tmpl ; do
            if [ -f "$i" ] ; then
	        echo -e "    " `basename $i .pre` "\t"
	        grep '^#JR: ' $i | sed -e 's/#JR: /        /g'
	        grep '^#DESC: ' $i | sed -e 's/#DESC: /        /g'
	        echo ''
            fi
        done
    else
        echo "Remember that you may copy one or more templates to your current directory"
        echo "and modify them manually to suit your needs."

    fi
    echo ""
}


# NAME
#	mol2toxyz - convert a MOL2 file to XYZ format
#
# SYNOPSIS
#	mol2toxyz molecule.mol2
#
# DESCRIPTION
#	Take a molecule in a MOL2 file (a file whose name ends in .mol2)
#	and convert to XYZ format using the same file name but with a
#	.XYZ extension.
#
#    (c) José R. Valverde
#
function mol2toxyz {
    local file=$1
    
    if [ ! -s $file ] ; then echo "mol2toxyz ERROR: invalid input file" ; return ; fi
    # extract file extension
    local ext="${file##*.}"
    # remove file extension
    local base="${file%.*}"
    # $base contains the path name, hence everything
    # will happen at the destination path name

    #
    # generate an XYZ from a mol2 file
    #
    if [ "$ext" == "mol2" -a ! -s $base.xyz ] ; then
        local i=0
        while read no atom x y z typ n res charge ; do
            i=$((i + 1))
            echo "$atom    $x    $y    $z" >> $base.zyx
        done < <( sed -n '/ATOM/,/BOND/ {/ATOM/d;/BOND/d;p}' $file )
	#        ^select between ATOM and BOND and delete these
        #         two lines
        echo "$i" > $base.xyz
        echo "$base" >> $base.xyz
        cat $base.zyx >> $base.xyz
        rm $base.zyx
    fi
}


# NAME
#    usage
#
# SYNOPSIS
#    usage ; exit
#
# DESCRIPTION
#    Print an explanation on how to use the program
#
#    (c) José R. Valverde
#
function usage() {
    echo "Usage: $ME -v -h -i file.xyz -c comp"
    echo "           -q charge -m multiplicity -B basis, -A accuracy,"
    echo "           -E equations -M model -C vonvergence -S spinmodel"
    echo "           -G gradients"
    echo ""
    echo "       $ME --verbose --help --input file.xyz --computation comp"
    echo "           --charge charge --multiplicity mult --basis basis,"
    echo "           --accuracy acc --scf-method meth --model-chem model"
    echo "           --scf-convergence conv --spin-model spinmodel"
    echo "           --grads gradients"
    echo ""
    echo "      -v --verbose    Increase verbosity level"
    echo "      -h --help       Print this help"
    echo "      -i --input	Input coordinate file in XYZ or MOL2 format"
    echo "      -c --computation Computation to carry out. Computations"
    echo "                      are summarized in parameter files in a"
    echo "                      common template directory or in your"
    echo "                      current directory.Use 'help' to obtain"
    echo "                      a list of available predefined computations"
    echo "      -q --charge     Total charge of the system. Use 'help' for"
    echo "                      more information"
    echo "      -m --multiplicity Multiplicity of the system. Use 'help' for"
    echo "                      more information"
    echo "      -g --guess      Method to guess the initial Hessian matrix"
    echo "                      usually SuperPos or Core. Use 'help' to get"
    echo "                      more details."
    echo "      -B --basis      Basis sets to use, as a comma-separated list"
    echo "                      with no spaces. Specify 'help' for more info"
    echo "                      or 'list' to get a list of basis sets that"
    echo "                      are compatible with your molecular system"
    echo "      -A --accuracy   Desired accuracy for the computation, as"
    echo "                      a comma-separated list without spaces. Use"
    echo "                      'help' for more details."
    echo "      -E --scf-method Equations to use to solve the SCF method "
    echo "                      as a comma-separated list without spaces."
    echo "                      Specify 'help' for more information"
    echo "      -M --model-chem Model Chemistries to use as a comma-separaed"
    echo "                      list without spaces. Indicate 'help' for "
    echo "                      more details"
    echo "      -C --scf-convergence Derivation methods to apply during"
    echo "                      convergence, as a comma-separated list"
    echo "                      without spaces, use 'help' for details"
    echo "      -S --spin-model Type of spin system to calculate (one of"
    echo "                      R (restricted, closed shell), U (unrestricted,"
    echo "                      open shell) or G (generalized), as a comma"
    echo "                      separated list"
    echo "      -G --grads      Type of gradients to compute and methods to"
    echo "                      compute these gradients, as a comma separated"
    echo "                      list for the whole calculations. This applies"
    echo "                      to the total calculation, not to each step"
    echo "                      separately. It is given in CSV so you can"
    echo "                      define and fine tune what is the goal "
    echo "                      calculation to accomplish."
    echo ""
    echo "    Sample usage:"
    echo "      $ME -i mymolecule.xyz -c optimize -q -1 -m 2 -A good,tight"
    echo ""
    echo "    © José R. Valverde, CNB/CSIC, 2011-2015"
    echo ""
    return
}


# NAME
#    charge_help
#
# SYNOPSIS
#    charge_help ; exit
#
# DESCRIPTION
#    Explain how to use the -q --charge command line switch
#
#    (c) José R. Valverde
#
function charge_help() {
    echo "
    -q --charge charge
    
    Specify the charge of your system using a positive or negative
  natural number, for example
  
      $ME -q -2
    
    An ion is an atom or molecule in which the total number of e- does
  not equal the total number of protons in the nucleus, giving the 
  molecule a net positive or negative charge.
  
    Ions may have uncoupled spin electrons. These spins will add to
  the behavious of the molecules in magnetic fields. Please, see the
  help on multiplicity to learn more about specifying uncoupled spin
  electrons.
"
    return
}


# NAME
#    multiplicity_help
#
# SYNOPSIS
#    multiplicity_help ; exit
#
# DESCRIPTION
#    Explain how to use the -m --multiplicity command line switch
#
#    (c) José R. Valverde
#
function multiplicity_help() {
    echo ""
    echo "    -m --multiplicity mult"
    echo ""
    echo "    Specify multiplicity as a positive natural number."
    echo "  As a rule, it is the number of unpaired spin electrons + 1"
    echo ""
    echo "    Formally, multiplicity is a measure of unpaired electron spin"
    echo "  and is calculated as 2 · S + 1, where S is the sum of umpaired"
    echo "  spins (Σm_s). Since an unpaired electron has a spin of ½, 2·S"
    echo "  yields the number of unpaired spin electrons: a molecule with 1 "
    echo "  unpaired e- has a spin of ±½, 2 · ½ = 1 and M = 1 + 1 = 2 "   
    echo "  (singlet state). Two unpaired spin e- would yield a triplet state,"
    echo "  and so on".
    echo ""
    echo "    Note that if you have two unpaired e-, their spins may be"
    echo "  coupled (+½ and -½, M=1) or not (+½ and +½ or -½ and -½, M=3)"
    echo ""
    echo "    Remember to consider Hund's rule when computing atomic multiplicity."
    echo "  For closed-shell molecules, which follow the octet rule, M = 1"
    echo "  Molecular fragments and radicals may have multiplicity > 1. Usually,"
    echo "  organic radicals will have M = 2 (with some rare exceptions),"
    echo "  carbenes and biradicals may have M = 1 or M = 3 (depending on whether"
    echo "  the two unpaired e- have different or the same spin). D-block and some"
    echo "  f-block elements require that you remember ligand field theory, and"
    echo "  relativistic effects (spin-orbit coupling) should be also taken into"
    echo "  account for heavy elements."
    echo ""
    echo "    As a general rule, however, in most organic chemistry cases, you"
    echo "  can rely on M = 1 for closed-shell molecules, M = 2 for mono-radicals"
    echo "  and you can try both, M = 1 or M = 3 for biradicals. For higher radicals"
    echo "  use your best judgement."
    echo ""
    echo "    If you do not specify the multiplicity for a radical"
    echo "  we will assume that a maximum of electrons is spin-coupled"
    echo "  and use M = 1 radicals with an even number of e- and "
    echo "  M = 2 for radicals with an odd number of e-"
    echo ""
    echo " IMPORTANT: THESE ARE ONLY A FEW RULES OF THUMB. CHECK YOUR"
    echo "   CHEMISTRY!!!"
    echo ""
    return
}


# NAME
#    guess_help
#
# SYNOPSIS
#    guess_help ; exit
#
# DESCRIPTION
#    Explain how to use the -g --guess command line switch
#
#    (c) José R. Valverde
#
function guess_help() {
    echo "
    -g --guess guess
    
    This is the methos used to obtain an initial guess for the values of
  the Hessian matrix to start the first step of the calculation. Choosing
  an appropriate initial guess will speed up the calculation requiring
  less iterations to reach convergence and will increase your chances
  of succeeding in getting the results.
    
    The method used to obtain an initial guess of the Hessian may be one of
    	SuperPos        -- Density matrix from superoposition of atomic
                           STO-NG densities. This is far superior to the
                           Core method, specially for large
                           basis sets and molecules.
        Core		-- Obtain guess MO coefficients diagonalizing the
                           core Hamiltonian matrix. Works best for small
                           basis sets and degrades as molecule and basis
                           set sizes increase.
        Restart		-- used when restarting or continuing MD simulations
        ReGuess		-- used when restarting or continuing MD simularions
        CPSCF (unused for now)
        Dipole (unused for now)
        
    The guess will be used in the initial calculation of a multi-step
  computation to start from a loose guess at the system paramteres. The
  first step will normally use a quick calculation method to obtain a
  more accurate matrix that may be used as the initial guess to feed
  a subsequent, higher-accuracy calculation.
    "
    return
}


# NAME
#    is_valid_guess
#
# SYNOPSIS
#    is_valid_guess "Guess"
#
# DESCRIPTION
#    Check if the first argument is a string that matches ONE of the
#    valid values for FreeON configuration key "Guess=", the method
#    to use to obtain the initial guess for the SCF computations.
#
#    (c) José R. Valverde
#
function is_valid_guess() {
    local guess=('SuperPos' 'Core' 'Restart' 'ReGuess')
    for (( i = 0; i < ${#guess[@]}; i++ )) ; do
       #echo "$i ${guess[$i]} $1"
       if [ "${guess[$i]}" == "$1" ]; then
           return 0
       fi
    done
    #echo no match
    return 1
}


# NAME
#    gradients_help
#
# SYNOPSIS
#    gradients_help ; exit
#
# DESCRIPTION
#    Provide information on how to use the -G --grad command line switch
#
#    (c) José R. Valverde
#
function gradients_help() {
    echo "
    -G --grad gradient_evaluation,...
    
    These are options that control the type of gradient to compute
    and how it is to be calculated. Basically, we define whether we
    should do one-step, compute first derivatives, second derivatives,
    etc... for 1SCF, forces, frequencies, MD calculations, etc... and
    which methods we want to use to compute these gradients/derivatives.
    
    One or more of the following, separated by commas:
    
        MaxSteps          -- Maximum number of geometry steps
        OneForce          -- Perform one force evaluation, with print out
	                     of the forces
        Scan              -- Scan from Geometry-1 to Geometry-2
        Optimize          -- Geometry Optimization
        MolecularDynamics -- Molecular Dynamics
        HybridMontecarlo  -- Hybrid Monte-Carlo
        TSSearch          -- Transition State search
        GDIIS             -- GDIIS
        ApproxHessian     -- Approximate diagonal hessian in internal 
	                     coordinates
        PrimInt           -- Coordinate type for gradient operations (internal
        Cartesian            or cartesian)
        SteepestDescent   -- Different cartesian optimizer types: steepest 
                             descent
        CG                   Conjugate gradients
        Global-CG            Globally-convergent conjugate gradients
        LBFGS                Limited-memory Broyden-Fletcher-Goldfrab-Shanno
                             iterative method for unconstrained nonlinear 
                             optimization
        Global-LBFGS
	NumFreq           -- Hessian and frequencies
    
    NOTE: it may also include other directives such as geometry optimization
    keys (e.g. BiSect HBondOnly DoGradNorm, NoFragmConnect...)
    "
    return
}


# NAME
#    is_valid_gradient
#
# SYNOPSIS
#    is_valid_gradient "Grad"
#
# DESCRIPTION
#    Check if the string provided as first argument tly exacmatches one
#    of the valid values for the the FreeON "Grad=" configuration key.
#
#    (c) José R. Valverde
#
function is_valid_gradient()
{
    local grad=( \
        'MaxSteps' \
        'OneForce' \
        'Scan' \
        'Optimize' \
        'MolecularDynamics' \
        'HybridMontecarlo' \
        'TSSearch' \
        'GDIIS' \
        'ApproxHessian' \
        'PrimInt' \
        'Cartesian' \
        'SteepestDescent' \
        'CG' \
        'Glocal-CG' \
        'LBFGS' \
        'Global-LBFGS' \
	'NumFreq' )
    for (( i = 0; i < ${#grad[@]}; i++ )); do
       #echo "${grad[$i]} $1"
       if [ "${grad[$i]}" == "$1" ]; then
           return 0
       fi
    done
    #echo no match
    return 1
}


#global array: valid_basis_sets
export valid_basis_sets=()

# NAME
#    find_valid_basis_sets
#
# SYNOPSIS
#    find_valid_basis_sets "moleculefile.xyz"
#
# DESCRIPTION
#    Return the list of basis sets that are available for a computation. 
#    If the arguments are provided, then all available basis sets are 
#    returned, but if a file name is provided, then this file is taken as 
#    an XYZ file containing a molecule and the list of valid basis sets is 
#    screened to leave only those that are parametrized for all atoms in 
#    the molecules, i. e., valid_basis_sets will contain only those basis
#    that can be used for this molecule and lack any that would be
#    unsuitable for it (because it does not support all required atoms).
#
#    CAUTION: currently, this function fills in a global array named
#    valid_basis_sets as a side effect. FUNCTION WITH SIDE EFFECTS!
#
#    (c) José R. Valverde
#
function find_valid_basis_sets() {
    # file must be an XYZ file
    local f=$1
    local atom
    
    # list only basis sets with support for all atoms in
    # the specified molecule to analyze, if any
    #
    
    if [ "$f" == "" -o ! -s "$f" ] ; then
        #ls -C $BASIS_SETS/*.bas | sed -e 's$.*/$$g' -e 's/.bas//g' | column
        # set global list of valis basis sets
        # for use in is_valid_basis_set()
        echo `/bin/ls -1 $BASIS_SETS/*.bas | \
             sed -e 's$.*/$$g' -e 's/.bas//g' | tr '\n' ' ' `
        return
    fi
    
    #echo "List of valid basis sets for your input molecule $f"
    #echo ""

    # initially all basis sets are valid
    # fill in an array with the list of all valid basis sets
    valid_basis_sets=( `/bin/ls $BASIS_SETS/*.bas 2>/dev/null | tr '\n' ' '` )
    
    # get list of atoms
    #tail -n +3 "$f" | cut -d' ' -f1 | sort | uniq | \
    while read atom ; do
        if [ "$atom" == '' ] ; then continue ; fi
	# Get list of basis sets that contain this atom
        #   starting from the list that contained all previous atoms
        valid_basis_sets=( `grep -l -E -i "^ $atom +0$" ${valid_basis_sets[@]} | tr '\n' ' '` )
	#echo "XXX ${valid_basis_sets[@]}"
    done < <(tail -n +3 "$f" | cut -d' ' -f1 | sort | uniq)
    # clean up file names down to basis-set names
    echo "${valid_basis_sets[@]}" | tr ' ' '\n' | \
        sed -e 's%.*/%%g' -e 's/\.bas//g' | tr '\n' ' '
    return
}


# NAME
#    list_basis_sets
#
# SYNOPSIS
#    list_basis_sets moleculefile.xyz ; exit
#
# DESCRIPTION
#    List the basis sets that can be used with the specified molecule
#    (i.e., that support all atoms in the molecule). If no molecule is
#    specified, list all available basis sets.
#
#    (c) José R. Valverde
#
function list_basis_sets() {
    echo "These are the valid basis sets"
    echo ""
    find_valid_basis_sets $* | tr ' ' '\n' | column
    return
}

# Old implementation
#
#    (c) José R. Valverde
#
function list_basis_sets_old() {
    # file must be an XYZ file
    local f=$1
    
    # list only basis sets valid with support for all atoms in
    # the molecule to analyze
    #
    
    if [ "$f" == "" ] ; then
        # if no input file then list all
        ls -C $BASIS_SETS/*.bas 2>/dev/null | less
        exit
    fi
    
    echo "List of valid basis sets for your input molecule $f"
    echo ""

    # initially all basis sets are valid
    ls -1 $BASIS_SETS/*.bas > tmpVBS

    # get list of atoms
    tail -n +3 $f | cut -d' ' -f1 | sort | uniq | tr '[:lower:]' '[:upper:]' | \
    while read atom ; do
        if [ "$atom" == '' ] ; then continue ; fi
	#echo "'$atom'"
        # Get list of basis sets that contain this atom
        #   starting from the list that contained all previous atoms
        grep -l -E "^ $atom +0$" `cat tmpVBS | tr '\n' ' '` > tmpVBS.new
        cp tmpVBS.new k.$atom
        mv tmpVBS.new tmpVBS
    done
    # print neatly
    sed -e 's%.*/%%g' -e 's/\.bas//g' tmpVBS | column #| less
    #rm tmpVBS
    return
}


# NAME
#    is_valid_basis_set
#
# SYNOPSIS
#    is_valid_basis_set $BASIS $XYZFILE
#
# DESCRIPTION
#    check if the specified basis set is among the list of valid
#    basis sets for the molecule specified (or if none is specified,
#    among the list of all known basis sets).
#
#    This implementation first obtains a list of valid basis sets
#    and then check if the specified set is in it. An alternative
#    solution might be to check if this concrete basis set has support
#    for all atoms in the molecule, or if there is no molecule, then
#    if it is in the list of known basis sets...
#
#    (c) José R. Valverde
#
function is_valid_basis_set() {
    local basis="$1" file="$2"
    
    #echo XXX "$basis" "$file"
    #find_valid_basis_sets "$file"
    for i in `find_valid_basis_sets "$file"` ; do
       #echo "$i $basis"
       if [ "$i" == "$basis" ] ; then
           return 0
       fi
    done
    #echo no match
    return 1
}


# NAME
#    basis_help
#
# SYNOPSIS
#    basis_help ; exit
#
# DESCRIPTION
#    Print information on the use of the -B --basis command line option
#
#    (c) José R. Valverde
#
function basis_help() {
echo "
    -B --basis
    
    Specify the basis sets to use during the computation as a comma
  separated list with no spaces, for instance
  
      $ME -B STO-3G,STO-6G-SPLIT

    Basis sets are tightly associated to the number of refinement
  steps to be used during the calculation.

    Computations can be done in one or two steps. Generally, the
  computation will start with an initial guess for the Hessian matrix,
  and then one or more steps where you compute the properties with
  increasing precision. You need to specify the parameters for each 
  of the successive calculation steps, and may choose totally
  different calculations at each refinement step.
    
     When the calculations are done in one step, only one basis set 
  is needed (e.g. -B 6-31G**-SPLIT). When they are done in two steps, 
  the first basis set specified will be used first, and once the 
  first calculation has converged, the second basis set will be used 
  to further refine the results.
  
    To help you select appropriate basis sets, and since not all of
  them support all the atoms in the periodic table, you can use the
  'list' option to -B with a molecule file, e.g.:
  
      $ME -i molecule.xyz -B list
    
    This will extract all the atoms in your molecule and match them
  against the available basis sets, listing only those basis sets 
  that contain parameters for all the atoms in your molecule and
  can be used to run computations on your system.
"
exit
}


# NAME
#    accuracy_help
#
# SYNOPSIS
#    accuracy_help ; exit
#
# DESCRIPTION
#    Print details on the use of the -A --accuracy command line option
#
#    (c) José R. Valverde
#
function accuracy_help() {
    echo "
    -A --accuracy
    
    Specify the basis sets to use during the computation as a comma
  separated list with no spaces, for instance
  
      $ME -A loose,good

    Accuracy is closely associated to the number of refinement
  steps to be used during the calculation.

    Computations can be done in one or two steps. Generally, the
  computation will start with an initial guess for the Hessian matrix,
  and then one or more steps where you compute the properties with
  increasing precision. You need to specify the parameters for each 
  of the successive calculation steps, and may choose totally
  different calculations at each refinement step.
    
     When the calculations are done in one step, only one accuracy 
  is needed (e.g. --accuracy tight). When they are done in two steps, 
  the first calculation will be run until the desired accuracy has
  been reached, and successive steps will be run to the corresponding
  accuracies.
  
      Valid options for --accuracy are (they are self-explanatory)

      	Loose
        Good
        Tight
        VeryTight
"
    exit
}


# NAME
#    is_valid_accuracy
#
# SYNOPSIS
#    is_valid_accuracy $acc
#
# DESCRIPTION
#    Check if the specified accuracy is among the list of possible values
#    for the "Accuracy=" configuration key
#
#    (c) José R. Valverde
#
function is_valid_accuracy()
{
    local acc=('Loose' 'Good' 'Tight' 'VeryTight')
    for (( i = 0; i < ${#acc[@]}; i++ )); do
       #echo "${acc[$i]} $1"
       if [ "${acc[$i]}" == "$1" ]; then
           return 0
       fi
    done
    #echo no match
    return 1
}


# NAME
#    scf_method_help
#
# SYNOPSIS
#    scf_method_help ; exit
#
# DESCRIPTION
#    Print details on the use of the -E --scf-method command line option
#
#    (c) José R. Valverde
#
function scfmethod_help() {
    echo "
    -E --scf-method method
    
    Method use to carry out the SCF calculation. Different methods will
    produce different speed-ups. Generally speaking, RH is the traditional
    approach. 
    
    The other methods implement various linear-scaling schemes.
    PM is a trace-preserving canonical approach with good properties.
    TRS4 does not enforce strictly trace preservation but may be 1 order 
    of magnitude faster and more accurate than PM with STO-nG or 6-31G**.
    
    You may want to try different methods to find the fastest for you,
    or better yet, review the literature to know the details.
    
    SCF calculation method must be one of:
    	RH      -- restricted Roothan-Hall
        SDMM    -- restricted simplified density matrix minimization
        PM      -- restricted Palser-Manulopolus Purification
        TC2     -- restricted quadratic trace correcting purification
        TC4     -- restricted quartic trace correcting purification
        TRS4    -- restricted quartic trace re-setting purification
    "
    exit
}


# NAME
#    is_valid_method
#
# SYNOPSIS
#    is_valid_method $METH
#
# DESCRIPTION
#    Check if the method specified matches one of the valid values
#    for the "SCFMethod=" configuration key of FreeON
#
#    (c) José R. Valverde
#
function is_valid_method() {
    local meth=('RH' 'SDMM' 'PM' 'TC2' 'TC4' 'TRS4')
    for (( i = 0; i < ${#meth[@]}; i++ )) ; do
       #echo "${meth[$i]} $1"
       if [ "${meth[$i]}" == "$1" ] ; then
           return 0
       fi
    done
    #echo no match
    return 1
}


# NAME
#    scfconvergence_help
#
# SYNOPSIS
#    scfconvergence_help ; exit
#
# DESCRIPTION
#    Print information on how to use the -C --scf-convergence command line 
#    option
#
#    (c) José R. Valverde
#
function scfconvergence_help() {
    echo "
    -C --scf-convergence
    
    SCF convergence method must be one of:
        DIIS       -- Direct inversion in the iterative subspace (usually 
                      the fastest method to reach a minimum once in the
                      convergence tegion) also known as Pulay mixing
        ODA        -- the optimal damping algorithm (more efficient for the
                      early iterations of the SCF procedure from crude 
                      approximations)
        ODA-DIIS   -- Mixed approach: start with ODA and switch to DIIS
	              You may use this to speed up initial calculations
		      from a poor guess and then switch to accurate on 
		      the fly
        DIIS-ODA   -- DIIS, then ODA on fail
                      This is useful to ensure that if an initially
		      accurate calculation fails, the method reverts
		      to the cruder ODA to converge
	DIIS-INC   -- DIIS with incremental Fock builds
        SMIX       -- Stanton mixing, a fast method to convergence
"
    exit
}


# NAME
#    is_valid_conv
#
# SYNOPSIS
#    is_valid_conv $CONV
#
# DESCRIPTION
#    Check if the specified argument is in the list of valid values
#    for the SCFConvergence configuration key of FreeON
#
#    (c) José R. Valverde
#
function is_valid_conv() {
    local conv=('DIIS' 'ODA' 'ODA-DIIS' 'DIIS-ODA' 'DIIS-INC' 'SMIX')
    for (( i = 0; i < ${#conv[@]}; i++ )); do
       #echo "${conv[$i]} $1"
       if [ "${conv[$i]}" == "$1" ]; then
           return 0
       fi
    done
    #echo no match
    return 1
}


# NAME
#    model_chem_help
#
# SYNOPSIS
#    model_chem_help , exit
#
# DESCRIPTION
#    Print details on how to use the -M --model-chem command line option
#
#    (c) José R. Valverde
#
function modelchem_help() {
    echo "
    -M --model-chem
    
    The chemical model to use may be one of
      Coulomb only    
        Hartree        -- Coulomb only exchange terms
      Exchange only
        HF             -- Hartree-Fock exchange terms
        SlaterDirac    -- Slater-Dirac exchange functional
        XAlpha         -- X(α) or X-Aplha exchange functional
        B88x           -- Becke's 1988 exchange functional
        PBEx           -- Perdew, Burke and Erzenhof's 11996 functional
        PW91x          -- Perdew and Wang's 1991 functional
      Pure exchange-correlation functionals
        VWN3xc         -- Vosko, Wilk and Nusair 1980 correlation functional 
                          (III) for the uniform gas (a.k.a. LSD, Local Spin
                          Density) correlation
        vWN5xc         -- Vosko, Wilk and Nusair functional fitting the Ceperly
                          Alder solution to the uniform electron gas
        PW91xc         -- Perdew and Wang's 1991 gradient-corrected correlation
        PW91LYP        -- PW91 and LYP (Lee, Yang and Parr correlation
                          functional with both, local and non-local terms)
        BLYPxc         -- Combination of Becke and LYP exchange functionals
        BPW91xc        -- becke 1988 exchange, Perdew 1991 nonlocal and
                          Perdew-Wang 1991 local correlation
        PBExc          -- Perdew, Burke and Erzenhof exchange correlation 
        HCTH93xc       -- HCTH/93 exchange-correlation functional
        HCTH120xc      -- HCTH/120 exchange-correlation functional
        HCTH147xc      -- HCTH/147 exchange-correlation functional
        HCTH407xc      -- HCTH/497 exchange-correlation functional
        XLYPxc         -- Extended functional combining Slater local,
                          Becke 88 nonlocal and Perdew-Wang 91 nonlocal,
                          Lee-Yang-Parr 1988 correlation
      Hybrid exchange-correlation functionals
        B3LYP          -- Becke 88 nonlocal + Slater local + Hartree-Fock
                          exchange, Lee-Yang-Parr 1988 local and nonlocal
                          + VWN formula 1 RPA local correlation (same as
                          NWchem and Gaussian)
        B3LYP/VWN5     -- Same as B3LYP but with VWN formula 5 (same as
                          GAMESS(US) B3LYP)
        PBE0           -- Perdew-Burke-Ernzerhof 1996 + Hartree-Fock
                          exchange, Perdew-Burke-Ernzerhof 1996 nonlocal
                          + Perdew-Wang 1991 LDA local correlation
        X3LYP          -- Extended hybrid functional combining Slater local,
                          Becke 88 nonlocal, and Perdew-Wang 91 nonlocal
                          exchange + Hartree-Fock, Lee-Yang-Parr 1988 local
                          and nonlocal + VWN formula 1 RPA local correlation
    "
    exit
}


# NAME
#    is_valid_model
#
# SYNOPSIS
#    is_valid_model $MOD
#
# DESCRIPTION
#    Check if the specified model is in the list of valid values for the
#    ModelChem configuration key of FreeON
#
#    (c) José R. Valverde
#
function is_valid_model()
{
    local mdl=( \
        'Hartree' \
        'HF' \
        'SlaterDirac' \
        'XAlpha' \
        'B88x' \
        'PBEx' \
        'PW91x' \
        'VWN3xc' \
        'vWN5xc' \
        'PW91xc' \
        'PW91LYP' \
        'BLYPxc' \
        'BPW91xc' \
        'PBExc' \
        'HCTH93xc' \
        'HCTH120xc' \
        'HCTH147xc' \
        'HCTH407xc' \
        'XLYPxc' \
        'B3LYP' \
        'B3LYP/VWN5' \
        'PBE0' \
        'X3LYP' \
    )
    for (( i = 0; i < ${#mdl[@]}; i++ )); do
       #echo "${mdl[$i]} $1"
       if [ "${mdl[$i]}" == "$1" ]; then
          return 0
       fi
    done
    #echo no match
    return 1

}


# NAME
#    spinmodel_help
#
# SYNOPSIS
#    spinmodel_help ; exit
#
# DESCRIPTION
#    Print information explaining how to use the -S --spin-model command
#    line option
#
#    (c) José R. Valverde
#
function spinmodel_help()
{
    echo "    -S --spin-model [RrUuGg],..."
    echo ""
    echo "    Spin model may be one of R U or G, and should be specified"
    echo "        for each calculation step as a comma-separated list"
    echo "        R -- restricted (closed shell) calculation"
    echo "        U -- unrestricted (open shell) calculation"
    echo "        G -- generalized calculation (noncollinear spin DFT)"
    exit
}


# NAME
#    is_valid_spinmodel
#
# SYNOPSIS
#    is_valid_spinmodel $SPIN
#
# DESCRIPTION
#    Check if the value specified is among the list of valid values for
#    the "SpinModel" configuration key of FreeON
#
#    (c) José R. Valverde
#
function is_valid_spinmodel() {
    if [[ "$1" = [RrUuGg] ]] ; then
        return 0	# valid
    else
        return 1	# invalid
    fi
}


# NAME
#    check_csv
#
# SYNOPSIS
#    check_csv method val1,val2,val3 [optional_arguments]
#
# DESCRIPTION
#    Check a comma-separated list of values using the method specified
#    This function will split the list into its component values and
#    call the method on each of them separately, optionally adding any
#    extra options provided when called. If the test function accepts
#    all the elements of the list as valid, then the list is deemed
#    valid as well.
#
#    (c) José R. Valverde
#
function check_csv() {
    local meth list i
    meth=$1 ; shift
    # change ',' to spaces
    i="$IFS" 
    IFS=',' list="$1" ; shift
    IFS="$i"
    for i in $list
    do
        #echo $i
        # pass along any remaining arguments to the comparison method
        if ! $meth $i $* ; then
            return 1
        fi
    done
    return 0
}


# NAME
#    modify_inp_value
#
# SYNOPSIS
#    modify_inp_value CONFIGFILE.inp key value
#
# DESCRIPTION
#    Modify the specified FreeON input configuration file so that
#    the pair key=value is substituted by the new values or, if it
#    wasn't present, it is added to the configuration.
#
#    (c) José R. Valverde
#
function modify_inp_value() {
    local inpufile="$1"
    name="$2"
    value="$3"
    
    # check if the input file contains a $name=some_value assignment
    # We'll match the lines to modify using case-insensitive matching
    # ###>>>	Note that the 'I' trick is not POSIX (it is a GNUism)
    if grep -qi "${name}=" "$inputfile" ; then
        # if it does, then modify that line
        #    find the line, remove everything after the = and insert the 
        #    new value
        sed -e "/^${name}=/I s/=.*/=${value}/g" "$inputfile" > "$inputfile".new
    else
        # if it does not then add a new $name=$value key
        #   after the <BeginOptions> line
        sed -e "/^<BeginOptions>/Ia ${name}=${value}" "$inputfile" > "$inputfile".new
    fi
    mv "$inputfile".new "$inputfile"

}


# NAME
#    xyz_natoms
#
# SYNOPSIS
#    xyz_natoms moleculefile.xyz
#
# DESCRIPTION
#    Return the number of atoms in an XYZ file
#
#    (c) José R. Valverde
#
function xyz_natoms() 
{
    local file=$1
    if [ ! -s $1 ] ; then return 0 ; fi
    natoms=`head -1 $file`
    return "$natoms"
}


# NAME
#    xyz_extract_hilola_conf
#
# SYNOPSIS
#    xyz_extract_hilola_conf moleculesfile.xyz
#
# DESCRIPTION
#    Given an XYZ file containing one or more molecule configurations
#    product of a FreeON calculation and containing the SCF energies in
#    the comment line, this function will locate and extract
#        - the configuration with highest energy
#        - the configuration with lowest energy
#        - the last configuration in the file
#    and name them accordingly (i.e., using the same filename as the 
#    original file, and inserting ".hi.", ".lo.", or ".last." before the 
#    xyz extension
#
#    (c) José R. Valverde
#
function xyz_extract_hilola_conf() 
{
    local file=$1
    local d f nam ext molsiz s e l i n energy loenergy hienergy

    d=`dirname $file`
    f="${file##*/}"	# filename without path
    nam="${f%.*}"	# name without extension (nor path)
    ext="${f##*.}"	# extension
    
    if [ ! -s "$file" ] ; then
        echo "xyz_stract_hilola_conf: $f does not exist"
        return
    fi
    if [ "$ext" != "xyz" ] ; then
        echo "xyz_extract_hilola_conf: $f is not an XYZ file"
        return
    fi
    # get molecule size
    molsiz=`head -n 1 "$file"`
    if [[ ! "$molsiz" =~ ^\ *[0-9]+$ ]] ; then
        echo "xyz_extract_hilola_conf: invalid molecule size. Is this an XYZ file?"
        return
    fi
    n=0    # line count used for error reporting
    loenergy="0.0E+1000" 	# ensure the first has a lower energy
    hienergy="-1.0E-1000"	# ensure the first has a higher energy
    cat $file | \
        while read s ; do
            n=$(($n+1))
            #echo "Size: $s"
	    # if it is a molecule size line
            if [[ ! "$s" =~ ^\ *[0-9]+$ ]] ; then
                echo "xyz_extract_hilola_conf: lost synchrony at line $n!"
                echo "        Check that $file is in XYZ format."
                rm $nam.last.xyz
	    fi
            read e	# get line containing Energy info"
            n=$(($n+1))
            #echo Energy: $e
            if [[ ! "$e" =~ ^Clone.* ]] ; then
                echo "xyz_extract_hilola_conf: lost synchrony at line $n!"
                echo "        Check that $file is in XYZ format."
                rm $nam.last.xyz
                continue
            fi
            #echo "Updating last"
	    # update last configuration
            echo "$s" > $d/$nam.last.xyz
            echo "$e" >> $d/$nam.last.xyz                
            for i in $(seq 1 $molsiz) ; do
                read l ; echo "$l" >> $d/$nam.last.xyz
                n=$(($n+1))
            done
            # find out potential energy
            # if it is an optimization run we look for 
            #      <SCF> = xxxDxx Hartree, yyyDyyy eV
            # if it is an MD run we might look for 
            #      Epot = xxxDxxx eV
            # but the value is repeated at then of the line in an <SCF> entry
            #echo $e
            if [[ "$e" =~ .*\<SCF\>.* ]] ; then
                # it is an optimization run, extract eV energy
                energy=`echo $e | sed -e 's/.*, //g' -e 's/ eV$//g' -e 's/D+/E/g'`
                #echo "Lowest: $loenergy Highest: $hienergy Curr: $energy"
            elif [[ "$e" =~ .*Epot.* ]] ; then
                energy=`echo $e | sed -e 's/.*Epot = /g' -e ' eV.*//g' -e 's/D+/E/g'`
            else
                echo "xyz_extract_hilo: Unknown energy in line"
                echo "    $e"
                return
            fi
            if (( $(bc -l <<< "$energy <= $loenergy") )) ; then
                #echo "lower"
                loenergy=$energy
                # update lowest energy configuration on <=
                cp $d/$nam.last.xyz $d/$nam.lo.xyz
            fi
            if (( $(bc -l <<< "$energy >= $hienergy") )) ; then
                #echo "HIGHER"
                #echo "$energy >= $hienergy"
                hienergy=$energy
                # update highest energy configuration on >=
                cp $d/$nam.last.xyz $d/$nam.hi.xyz
                #exit
            fi
        done
}


# NAME
#    xyz_extract_maxmin_confs
#
# SYNOPSIS
#    xyz_extract_maxmin_confs moleculesfile.xyz nconfs
#
# DESCRIPTION
#    Extract absolute maximum and minimum as well as the N local maxima
#    and minima and the last configuration in the specified file. The
#    file must be a FreeON XYZ geometries output file containing SCF
#    enerhies in the comment line of each configuration.
#    If the number of configurations to save is not specified, then all
#    local minima and all local maxima will be extracted.
#    The output files will be named after the input filename with a
#    suffix added before the XYZ extention:
#        - .lst.xyz : the last configuration in the multi-configuration 
#          XYZ file
#        - .min.xyz : the absolute minimum energy configuration
#        - .max.xyz : the absolute maximum energy configuration
#        - .min-###.xyz : A file containing the lowest ### local minima
#          where ### will be either the total number of local minima if
#          no value was specified, or else, the number of local minima
#          found up to and including the value specified (i.e. if there
#          were less local minima than requested, then ### will be the
#          number of local minima found)
#        - .max-###.xyz : A file containing the highest ### local minima
#          where ### is chosen as described above for local minima.
#    This implementation makes use of an array to hold all the configurations
#    and their coordinates, and then outputs the selected configurations. As
#    such, it may become memory expensive. An alternative implementation might
#    keep only the needed configurations instead and save memory. See the 
#    comments inside for more details.
#
#    (c) José R. Valverde
#
function xyz_extract_maxmin_confs() 
{
    local file=$1
    local nconfs=${2:-0}
    local -a minima=( )
    local -a maxima=( )
    local d f nam ext size prevE nextE currE n lastxyz left right i s e
    local minE maxE

    d=`dirname $file`
    f="${file##*/}"	# filename without path
    nam="${f%.*}"	# name without extension (nor path)
    ext="${f##*.}"	# extension
    
    if [ ! -s "$file" ] ; then
        echo "xyz_stract_min_conf: $f does not exist"
        return
    fi
    if [ "$ext" != "xyz" ] ; then
        echo "xyz_extract_min_conf: $f is not an XYZ file"
        return
    fi
    # get molecule size
    size=`head -n 1 "$file"`
    if [[ ! "$size" =~ ^\ *[0-9]+$ ]] ; then
        echo "xyz_extract_min_conf: invalid molecule size. Is this an XYZ file?"
        return
    fi
    
    
    n=0
    currE="0E00" 	
    prevE="0E00"	
    lastxyz=""
    minE="01.0E1000"
    maxE="-1.0E1000"
    nmin=0
    while read s ; do
        n=$(($n+1)) # count lines
        #echo "Size: $s"
	# if it is a molecule size line
        if [[ ! "$s" =~ ^\ *[0-9]+$ ]] ; then
	    continue
            echo "xyz_extract_min_conf: lost synchrony at line $n!"
            echo "                  Check that $file is in XYZ format."
        fi
        read e	# get line containing Energy info"
        x=$((x+1)) # count XYZ molecules/configurations
        #echo Energy: $e
        if [[ ! "$e" =~ ^Clone.* ]] ; then
            echo "xyz_extract_min_conf: lost synchrony at line $n!"
            echo "                  Check that $file is in XYZ format."
            continue
        fi
        # find out potential energy
        # if it is an optimization run we look for 
        #      <SCF> = xxxDxx Hartree, yyyDyyy eV
        # if it is an MD run we might look for 
        #      Epot = xxxDxxx eV
        # but the value is repeated at then of the line in an <SCF> entry
        #echo $e
        if [[ "$e" =~ .*\<SCF\>.* ]] ; then
            # extract the last energy in the line (in eV)
            nextE=`echo $e | sed -e 's/.*, //g' -e 's/ eV$//g' -e 's/D+/E/g'`
            #echo "Lowest: $loenergy Highest: $hienergy Curr: $energy"
        else
            echo "xyz_extract_hilo: Unknown energy in line"
            echo "    $e"
            return
        fi
        #echo "E-2=$prevE E-1=$currE E=$nextE"
        ###JR###
        # this will fail on a plateau (we should keep track of whether
        #	we are downhill or upfill) we rely on precision to not
        #	obtain exactly equal energies in consecutive points, or
        #	we could test for <= but then we would save all points
        #	in the plateau and should keep only one with "uniq" on column1
        left=`bc -l <<< "$currE < $prevE"`
        right=`bc -l <<< "$currE < $nextE"`
	#echo $left $right
        if [ "$left" == "1" -a "$right" == "1" ] ; then
            #echo "m $x: $prevE $currE $nextE" 
            #echo -n `bc -l <<< "    $prevE - $currE"`
            #echo `bc -l <<< "     $currE - $nextE"`
            #echo "local minimum found"
            # save its energy and XYZ in minima array
            #	they are those of the last read molecule
            minima=( "${minima[@]}" "$currE	$lastxyz" )
            # we could save memory if needed by doing the sort/tail here

            #echo "mv lastsaved to minimum"
            #for i in $(seq 1 $size) ; do
            #    echo "${lastconf[i]}"
            #done
        fi
        if [ "$left" == "0" -a "$right" == "0" ] ; then
            #echo "M $x: $prevE $currE $nextE" 
            #echo -n `bc -l <<< "    $prevE - $currE"`
            #echo `bc -l <<< "     $currE - $nextE"`
            maxima=( "${maxima[@]}" "$currE	$lastxyz" )
        fi
        #echo "save current as lastconf"
        #lastconf=( "$s" "$e" )
        #for i in $(seq 1 $size) ; do
        #    read l
        #    n=$(($n+1))
        #    lastconf=( "${lastconf[@]}" "$l" )
        #done 
        #lastxyz=`for i in $(seq 1 $size) ; do echo "${lastconf[i]}" ; done | tr '\n' '@'`
        lastxyz=`(echo "$s"; echo "$e"; \
        	  for i in $(seq 1 $size) ; do \
                      read l ; \
                      n=$(($n+1)) ; \
                      echo "$l" ; \
                  done) | tr '\n' '@'`

        prevE=$currE
        currE=$nextE
        
        if (( $(bc -l <<< "$currE <= $minE") )) ; then
            #echo "New minimum: $x $minE $currE"
            minxyz="$lastxyz"
            minE=$currE
        fi
        if (( $(bc -l <<< "$currE >= $maxE") )) ; then
            #echo "New maximum: $x $minE $currE"
            maxxyz="$lastxyz"
            maxE=$currE
        fi
    done < $file
    
    # last config is special: there is no next conf but it might also 
    # be a minimum
    if [ "$left" == "1" ] ; then
        minima=( "${minima[@]}" "$currE	$lastxyz" )
    fi
    # and by the way, we may as well save last, min and max
    echo "$lastxyz" | tr -d '\n' | tr '@' '\n' > $nam.lst.xyz
    echo "$minxyz"  | tr -d '\n' | tr '@' '\n' > $nam.min.xyz
    echo "$maxxyz"  | tr -d '\n' | tr '@' '\n' > $nam.max.xyz

    #for i in $(seq 0 ${#minima[@]}) ; do
    #    echo "$i: ${minima[$i]}"
    #done
    #echo ""
    #echo ""
    # sort minima array (which has the form E xyz@lined) and output lowest values
    if [ "$nconfs" -gt 0 ] ; then n=$nconfs ; else n=${#minima[@]} ; fi
    if [ ${#minima[@]} -lt $n ] ; then n=${#minima[@]} ; fi
    for i in $(seq 0 ${#minima[@]}) ; do
        echo "${minima[$i]}"
    done |\
         grep -v '^$' | sort -g | head -n $n | cut -f2 | tr -d '\n' | tr '@' '\n' \
         > $nam.min-$n.xyz
    # remove empty lines, sort numerically, select first $n, extract
    # the coordinates and revert back '@' to newlines

    # same for maxima
    if [ "$nconfs" -gt 0 ] ; then n=$nconfs ; else n=${#maxima[@]} ; fi
    if [ ${#maxima[@]} -lt $n ] ; then n=${#maxima[@]} ; fi
    for i in $(seq 0 ${#maxima[@]}) ; do
        echo "${maxima[$i]}"
    done |\
         grep -v '^$' | sort -g | head -n $n | cut -f2 | tr -d '\n' | tr '@' '\n' \
         > $nam.max-$n.xyz
}


# NAME
#    extract_range
#
# SYNOPSIS
#    extract_range start end file
#
# DESCRIPTION
#    Extract a line range from a file
#
#    (c) José R. Valverde
#
function extract_range() {
    start=${1:-0}	# start line of range
    end=${2:-0}		# end line of range
    file=${3:-""}	# if no file is specified it will act as a pipe
    
    # the tail | head solution is reportedly ~10% faster
    tail -n +$start $file | head -n $((end - start + 1))	# write to stdout
    # than the sed one
    #sed -n "${start},${end}p;${end}q" $file		# write to stdout
    #
}


# NAME
#    run_freeon
#
# SYNOPSIS
#    run_freeon $directory $job
#
# DESCRIPTION
#    Change to the specified directory and then run FreeON.
#    FreeON will try to read its options from a file that should
#    be named as the second option followed with a '.inp'
#    extension (i.e. a file named $ijob.inp). Results will be
#    saved using the same $job base name followed by a variety
#    of extensions, most prominently
#        - $job.std : Redirected standard output and standard error of
#            FreeON
#        - $job.out : Output file produced directly by FreeON
#        - $job.geometries : geometries produced by FreeON
#        - $job.coords.xyz : XYZ coordinates of the geometries produced
#        - $job.ccoords.xyz : same as above but centered for easier use
#        - $job.ccoords.{min|max|lst|min-###|max-###}.xyz : processed
#            coordinate files containing the absolute minimum energy,
#            absolute maximum energy, last and ### local minima and
#            local maxima configurations in the geometries output file;
#            these will be most useful after optimizations or MD runs.
#
#    (c) José R. Valverde
#
function run_freeon() {
    d=$1
    nam=$2
    if [ -z "$nam" -o ! -d "$d" ] ; then
        echo "$ME: ERROR run_freeon received less than three arguments"
        echo "    correct usage is run_freeon workdir basename"
	echo "    Got_ $ME $d $nam"
        exit
    fi
    
    pushd `pwd` >& /dev/null

    cd "$d"

    date -u >> "$nam".date

    # Run FreeON
    #	We assume it is on our path
    FreeON $nam.inp $nam.out $nam.log $nam.geometries &> $nam.std

    date -u >> "$nam".date

    if [ -e "$nam.geometries" ] ; then
        # IF THIS WAS AN MD RUN:
        # Keep only XYZ coordinates with MD data.
        #
        # match and output only
        #	one space
        #	ATOM-NAME (onr or more capitals)
        #   one or more spaces
        #   X-coordinate (one or more non-spaces)
        #   oe or more spaces
        #   Y-coordinate (non-spaces)
        #   oe or more spaces
        #   Z-coordinate (non-spaces)
        # on matching lines (everything otherwise) using
        #	sed -r -e 's/^( [A-Z]+ +[^ ]* *[^ ]* *[^ ]* *).*$/\1/g' > \
        #
        # Note: we might also match the longer but more specific
        # 	space
        #	ATOM SYMBOL (one or more capitals)
        #	one or more spaces
        #	X-coordinate (zero or more -, one or more numbers and possibly a '.'
        #		and maybe more numbers)
        #	one or more spaces
        #   Y-coordinate
        #	one or more spaces
        #   Z-coordinate
        # with:
        #   sed -r -e "/s/^( [A-Z]+ +-*[0-9]+\.*[0-9]* +-*[0-9]+\.*[0-9]* +[0-9]+\.*[0-9]*).*/\1/g" \
        #
        cat "$nam".geometries | \
          sed -r -e 's/^( [A-Z]+ +[^ ]* *[^ ]* *[^ ]* *).*$/\1/g' \
          -e 's/^ //g' > \
          "$nam".coords.xyz
        # center coordinates at (0,0,0) for easier visualization
        babel -c -ixyz "$nam.coords.xyz" "$nam.ccoords.xyz"
        
        # Extract absolute max, min, N local minima (points where the energy
        #     is smaller than both the previous and following configurations)
        #     and local maxima, and the last configuration
        xyz_extract_maxmin_confs "$nam".ccoords.xyz 10

    fi

    popd >& /dev/null

}


############################################################
# Process command line
############################################################

VERBOSE=0

# Parse the command line
# ----------------------
# Note that we use `"$@"' to let each command-line parameter expand to a 
# separate word. The quotes around `$@' are essential!
# We need TEMP as the `eval set --' would nuke the return value of getopt.
TEMP=`getopt -o vhi:c:q:m:g:B:A:E:M:C:S:G: \
     --long vebose,help,input:,computation:,charge:,multiplicity:,guess:,basis:,accuracy:,scf-method:,model-chem:,scf-convergence:,spin-model:,grads: \
     -n "$0" -- "$@"`

# an invalid option was given
if [ $? != 0 ] ; then usage >&2 ; exit 1 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
        case "$1" in
                -v|--verbose) 
                    VERBOSE=$(( $VERBOSE + 1 )) ; shift ;;
                    
                -h|--help) 
                    usage ; shift ;;

                -i|--input) 
                    #echo "INPUT FILE \`$2'" 
                    file=$2 ; shift 2 ;;
                    
                -c|--computation) 
                    c=$2 ; 
                    if [ "$c" == "help" ] ; then list_parameter_files ; exit ; fi
                    shift 2 ;;
                    
                -q|--charge)
                    # if $2 is a natural number, use it, ignore otherwise
                    if [[ $2 =~ ^-?\+?[0-9]+$ ]] ; then 
                        CHARGE=$2
                    else
                        charge_help ; exit
                    fi
                    shift 2 ;;
                
                -m|--multiplicity)
                    # it must be a positive natural number
                    if [[ $2 =~ ^\+?[0-9]+$ ]] ; then 
                        MULTIPLICITY=$2 
                    else
                        multiplicity_help ; exit
                    fi
                    shift 2 ;;

		-g|--guess)
                    if is_valid_guess $2 ; then
                        GUESS=$2
                    else 
                        guess_help ; exit
                    fi
                    shift 2 ;;
		
		-S|--spin-model)
		    if check_csv is_valid_spinmodel $2 ; then
		        SPINMODEL="$2"
		    else
		        spinmodel_help ; exit
		    fi
		    shift 2 ;;

		# from here on, these may be comma-separated values
                -B|--basis) 
                    BASIS=$2 ; 
                    if [ "$BASIS" == "help" ] ; then basis_help ; exit ; fi
                    if [ "$BASIS" == "list" ] ; then list_basis_sets "$file" ; exit ; fi
		    if ! check_csv is_valid_basis_set $BASIS $file ; then
		        echo "$ME: $BASIS is not valid, ignoring it"
		        BASIS=''
		    fi
                    shift 2 ;;
                
                -A|--accuracy) 
                    if check_csv is_valid_accuracy $2 ; then
                        ACCURACY=$2 ; 
                    else
                        accuracy_help ; exit
                    fi
                    shift 2 ;;

                -E|--scf-method) 
                    if check_csv is_valid_method $2 ; then
                        SCFMETHOD=$2 ; 
                    else
                        scfmethod_help ; exit
                    fi
                    shift 2 ;;

                -M|--model-chem)
                    if check_csv is_valid_model $2 ; then
                        MODELCHEM=$2 
                    else
                        modelchem_help ; exit
                    fi
                    shift 2 ;;

                -C|--scf-convergence)
                    if check_csv is_valid_conv $2 ; then
                        SCFCONVERGENCE=$2
                    else
                        scfconvergence_help ; exit
                    fi
                    shift 2 ;;
                
                -G|--grads)
                    if check_csv is_valid_gradient $2 ; then
                        GRADS=$2
                    else
                        gradients_help ; exit
                    fi
                    shift 2 ;;

                --) shift ; break ;;
                *) echo "Internal error!" >&2 ; usage ; exit 1 ;;
        esac
done


#####################################
# Process input file
#####################################

# remove file extension from full path name
base="${file%.*}"	# with directory name

# allow molecule name to be specified without extension
if [ "$base" == "$file" ] ; then 
    # specified filename has no extension
    if [ -s $file.xyz ] ; then
        # we give precedence to XYZ files when they exist
        file=$file.xyz
    elif [ -s $file.mol2 ] ; then 
        # otherwise we'll use a MOL2 file and convert it to XYZ
        file=$file.mol2
    fi
    # IMPORTANT!
    # if no f.xyz or f.mol2 exist, then, we assume that f is
    # an XYZ file with no -or an atypic- extension
fi
# at this point base has not changed, but file may have an added extension

#echo "$file ($base)"
if [ ! -f "$file" -o -z "$file" ] ; then
    usage ; exit
fi


# extract file extension
ext="${file##*.}"

# Check if it is a mol2 file: 
#   we need an XYZ: if one exists, use it, 
#   otherwise make one.
#   $ext will be used to know the original file type
if [ "$ext" = "mol2" ] ; then 
    if [ -s $base.xyz ] ; then 
        if [ $VERBOSE -gt 1 ] ; then
            echo "  $ME: WARNING! backing up existing $base.xyz"
        fi
        # count existing backups (if any)
        i = 0 ; while [ -e $file.$i ] ; do i=$(($i +1)) ; done
        mv $file $file.$i
        file=$base.xyz 
    fi
    if [ $VERBOSE -gt 1 ] ; then
        echo "  $ME: creating a new file $base.xyz"
    fi
    mol2toxyz $base.mol2
    file=$base.xyz
fi
# if the extension is neither XYZ nor MOL2 nor INP we assume it is an XYZ
# file with an atypical extension

# remove directory path
f="${file##*/}"
# extract name wihout path nor extension
nam="${f%.*}"		# without directory name for later name-composition
#echo "F=$f name=$nam ext=$ext"

# Bonus track:
#	Check if extension is .inp and if it is, then we will
# not generate an input file, but use the specified file directly
# instead.
###################################################
# IGNORE ALL AND RUN FREEON ON SPECIFIED INPUT FILE
###################################################
if [ "$ext" = "inp" ] ; then
    echo "$ME: WARNING!!!"
    echo "    you specified as input a .inp file!!!"
    echo ""
    echo "    We'll assume that this is NOT a coordinate file, but"
    echo "    an input file for FreeON (that, by the way, contains"
    echo "    the input coordinates) and use it as input for FreeON"
    echo "    directly instead."
    echo ""
    echo "    THIS IMPLIES THAT ALL OTHER OPTIONS WILL BE IGNORED"
    echo ""

    # ignore all other parameters and run with this input file
    # get file's directory
    #
    #       if $FILE undefined this will return "."
    d=`dirname "$file"`
    if [ -e $d/$nam ] ; then
        echo "$ME ERROR: $d/${nam} already exists. Cowardly refusing to proceed"
        exit
    fi
    mkdir -p $d/$nam
    cp $file $d/$nam/
    # run freeON on directory $d using input file $nam.inp
    run_freeon $d/$nam $nam

    # we are done
    exit
fi


##########################################
# Process computation parameters  file
##########################################

# allow to reference user parameter files by full name
if [ -f "$c" ] ; then
	compute="$c"
else
    # if the parameter file does not exist, list available ones
    if [ -z "$c" -o ! -f $FREEON_HOME/templates/$c.pre -a ! -f ./$c.pre ] ; then
        #echo -n "Total number of electrons = " ; calc_e $f
        list_parameter_files
	exit
    fi
    compute=""
    if [ -f $FREEON_HOME/templates/$c.pre ] ; then
	compute=$FREEON_HOME/templates/$c.pre
    fi
    # preempt with local version if it exists
    if [ -f `pwd`/$c.pre ] ; then
	compute=`pwd`/$c.pre
    fi
fi
# we will use $c from now on to build derivative filenames
#	that is why we sanitize it now
c=`basename $c .pre`

# this shouldn't happen.
if [ ! -f "$compute" ] ; then
	echo "$ME ERROR: template file $c does not exist"
        usage
	exit
fi

##########################################################
# Prepare computation
##########################################################

# get file's directory
#
#       if $FILE undefined this will return "."
d=`dirname "$file"`

# Build destination directory name
destdir="$d/${nam}_$c"

# if there were modifications, append them to the directory name
if  [ ! -z "$CHARGE" ] ; then destdir=${destdir}_q="$CHARGE" ; fi
if  [ ! -z "$MULTIPLICITY" ] ; then destdir=${destdir}_m="$MULTIPLICITY" ; fi
if  [ ! -z "$GUESS" ] ; then destdir=${destdir}_g="$GUESS" ; fi
if  [ ! -z "$SPINMODEL" ] ; then destdir=${destdir}_s="$SPINMODEL" ; fi
if  [ ! -z "$ACCURACY" ] ; then destdir=${destdir}_A=$"ACCURACY" ; fi
if  [ ! -z "$SCFMETHOD" ] ; then destdir=${destdir}_E="$SCFMETHOD" ; fi
if  [ ! -z "$MODELCHEM" ] ; then destdir=${destdir}_M="$GUESS" ; fi
if  [ ! -z "$CONVERGENCE" ] ; then destdir=${destdir}_C="$CONVERGENCE" ; fi
if  [ ! -z "$GRADS" ] ; then destdir=${destdir}_G="$GRADS" ; fi


# Check if a similar computation has already been run
if [ -e "$destdir" ] ; then 
    echo "$ME ERROR: ${destdir} already exists. Cowardly refusing to proceed"
    exit
fi
mkdir -p "$destdir"

# create .inp file
# we do it this way to ensure the path to $compute keeps being valid
#	if it points to a user-defined non-cwd file
inputfile="$destdir"/"$nam".inp


cat $compute > "$inputfile"

echo "<BeginGeometry>" >> "$inputfile"
tail -n +3 $nam.xyz >> "$inputfile"
echo "<EndGeometry>" >> "$inputfile"

# Advanced users may wish to modify specific options

### JR ###
###    NOTE:
###        We may need to include a lot more intelligence below. There may
###    be absurd combinations as well as options that demand suplementary
###    changes. We'll need to identify most of them and make the required
###    corrections.
###        For now, we'll rely on valid .pre configuration files
##########


# modify parameters if requested by the user

if [ ! -z "$CHARGE" ] ; then
    modify_inp_value "$inputfile" "Charge" "$CHARGE"
fi
if [ ! -z "$GUESS" ] ; then
    modify_inp_value "$inputfile" Guess "$GUESS"
fi
if [ -z "$MULTIPLICITY" ] ; then
    # if no multiplicity was specified, we'll assume the most coupled state,
    # where as many electrons are spin-coupled as possible
    nelec=`calc_e $f $CHARGE`
    unpaired=$(( $nelec % 2 ))
    if [ $unpaired -eq 1 ] ; then 
        MULTIPLICITY=$(( $unpaired + 1 ))
    else
        # otherwise we rely on the default provided by the computation file
        # which is 1 (all e- are paired)
        MULTIPLICITY="1"
    fi
fi
modify_inp_value "$inputfile" Multiplicity "$MULTIPLICITY"

#
# The next options are expressed as lists. A list is enclosed in
# parenthesis and values are separated by commas
#
if [ ! -z "$SPINMODEL" ] ; then
    # if specified in the command line, use the user's choice
    modify_inp_value "$inputfile" SpinModel "(${SPINMODEL})"
else
    # otherwise, try to set a wise choice
    #	We might try G if this is a DFT calculation, but it seems that
    #	    it is not yet implemented.
    if [ "$MULTIPLICITY" != "1" ] ; then
        modify_inp_value "$inputfile" SpinModel "(U)"
    fi
fi
if [ ! -z "$ACCURACY" ] ; then
    modify_inp_value "$inputfile" Accuracy "(${ACCURACY})"
fi
if [ ! -z "$BASIS" ] ; then
    modify_inp_value "$inputfile" BasisSets "(${BASIS})"
fi
if [ ! -z "$SCFMETHOD" ] ; then
    modify_inp_value "$inputfile" SCFMethod "(${SCFMETHOD})"
fi
if [ ! -z "$MODELCHEM" ] ; then
    modify_inp_value "$inputfile" ModelChem "(${MODELCHEM})"
fi
if [ ! -z "$SCFCONVERGENCE" ] ; then
    modify_inp_value "$inputfile" SCFConvergence "(${SCFCONVERGENCE})"
fi
if [ ! -z "$GRADS" ] ; then
    modify_inp_value "$inputfile" Grads "(${GRADS})"
fi


#################################################################
# Do the calculations
#################################################################

run_freeon "$destdir" "$nam"

exit

