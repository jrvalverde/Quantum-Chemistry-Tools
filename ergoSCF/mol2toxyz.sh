function mol2toxyz {
    file=$1
    
    # get file directory and move to it
    #
    #       if $file undefined this will return "."
    d=`dirname "$file"`
    pushd `pwd` > /dev/null
    cd $d


    # remove directory path
    f="${file##*/}"
    # extract file extension
    ext="${file##*.}"
    # remove file extension
    base="${f%.*}"

    #
    # generate an XYZ from a mol2 file
    #
    if [ "$ext" == "mol2" -a ! -s $base.xyz ] ; then
        i=0
        while read no atom x y z typ n res charge ; do
            i=$((i + 1))
            echo "$atom    $x    $y    $z" >> $base.zyx
        done < <( sed -n '/ATOM/,/BOND/ {/ATOM/d;/BOND/d;p}' $file )
        echo "$i" > $base.xyz
        echo "$base" >> $base.xyz
        cat $base.zyx >> $base.xyz
        #rm $base.zyx
    fi
}

function ergoSCF_update_mol2 {
    # this takes a charges file in sync with a mol2 file and adds charges to it.
    if [ -s $name.$GUESS.$BASIS.charges ] ; then
        # we have Mulliken charges computed
        babel -ixyz $FILE -omol2 $MOL2
        cp $MOL2 $MOL2.babel
# NOTE: SEE ERGOSCF.BASH FOR CORRECT VERSION!!!
        cat $name.$GUESS.$BASIS.charges | while read a b c d e i k charge ; do
            i=$((i + 1))
            echo $i $charge
            sed  -e "/ \+ $i .* 1  LIG/ s/\(.*\) LIG1.*/\1 OUT       $charge/"  $MOL2 > tmpFile.mol2
	    # num atom x y z atom_type molnum molname charge bit
            sed -E "/\s*$i\s+[^\s]+\s+[0-9.]+\s+[0-9.]+\s+[0-9.]+\s+[A-Za-z0-9]+/p"
            mv tmpFile.mol2 $MOL2
        done
    fi
}
