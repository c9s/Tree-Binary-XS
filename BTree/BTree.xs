#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct _btree_node BTreeNode;

struct _btree_node {  
    long key;
    // unsigned long size;
    BTreeNode* left;
    BTreeNode* right;
};

MODULE = BTree		PACKAGE = BTree		

TYPEMAP: <<END;

END

void
new(...)
    PPCODE:
        void *pad;
        Newx(pad, sizeof(BTreeNode), BTreeNode);

        SV* ret = newSV(0);
        SvUPGRADE(ret, SVt_RV);
        SvROK_on(ret);
        SvRV(ret) = (SV*)pad;

        SV * obj = newRV_noinc(ret);
        STRLEN classname_len;
        char * classname = SvPVbyte(ST(0), classname_len);
        HV * stash = gv_stashpvn(classname, classname_len, 0);
        sv_bless(obj, stash);
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(obj));

void
DESTROY(self)
    SV* self
    PPCODE:
        void* pad = SvRV(SvRV(self));
        Safefree(pad);
        SvRV(SvRV(self)) = 0;

