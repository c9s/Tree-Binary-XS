#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct _btree_node BTreeNode;
typedef struct _btree_pad BTreePad;

struct _btree_pad { 
    BTreeNode *root;
    HV * options;
};

struct _btree_node {  
    IV key;
    // unsigned long size;
    BTreeNode* left;
    BTreeNode* right;
    HV * payload;
};


BTreePad * btree_pad_new();

bool btree_insert(BTreeNode * node, IV key, HV * payload);

BTreeNode * btree_node_create(IV key, HV *payload);

BTreePad * btree_pad_new()
{
    BTreePad * pad = NULL;
    Newx(pad, sizeof(BTreePad), BTreePad);
    pad->root = NULL;
    pad->options = NULL;
    return pad;
}

BTreeNode * btree_node_create(IV key, HV *payload)
{
    BTreeNode * new_node = NULL;
    Newx(new_node, sizeof(BTreeNode), BTreeNode);
    new_node->payload = payload;
    new_node->key = key;
    new_node->left = NULL;
    new_node->right = NULL;
    return new_node;
}

bool btree_insert(BTreeNode * node, IV key, HV * payload) {
    if (key < node->key) {
        if (node->left) {
            return btree_insert(node->left, key, payload);
        } else {
            BTreeNode * new_node = btree_node_create(key, payload);
            node->left = new_node;
        }
        return 1;
    } else if (key > node->key) {
        if (node->right) {
            return btree_insert(node->right, key, payload);
        } else {
            BTreeNode * new_node = btree_node_create(key, payload);
            node->right = new_node;
        }
        return 1;
    } else if (key == node->key) {
        // raise error
        return 0;
    }
    return 0;
}


#define DEBUG 1

#define debug(fmt, ...) \
            do { if (DEBUG) fprintf(stderr, "DEBUG: " fmt "\n", ##__VA_ARGS__); } while (0)


MODULE = BTree		PACKAGE = BTree		

TYPEMAP: <<END;

END

void
new(...)
    PPCODE:
        BTreePad *pad = btree_pad_new();

        // printf("pad: %x\n", pad);

        // newHV();
        SV* ret = newSV(0);
        SvUPGRADE(ret, SVt_RV);
        SvROK_on(ret);
        SvRV(ret) = (SV*)pad;

        SV * obj = newRV_noinc(ret);
        STRLEN classname_len;
        char * classname = SvPVbyte(ST(0), classname_len);
        HV * stash = gv_stashpvn(classname, classname_len, 0);
        sv_bless(obj, stash);

        SV * options_ref = ST(1);
        if (options_ref) {
            HV * options_hv = (HV*) SvRV(options_ref);
            SvREFCNT_inc(options_hv);
            pad->options = options_hv;
        }
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(obj));


HV*
options(self_sv)
    SV* self_sv
    CODE:
        BTreePad* pad = (BTreePad*) SvRV(SvRV(self_sv));
        if (pad->options) {
            RETVAL = pad->options;
        } else {
            RETVAL = newHV();
        }
    OUTPUT:
        RETVAL

void
insert(self_sv, ...)
    SV* self_sv
    PPCODE:

    BTreePad* pad = (BTreePad*) SvRV(SvRV(self_sv));



    char *key_field = "key";

    if (!pad || !pad->options) {
        XSRETURN_UNDEF;
    }
    if (pad->options) {
        if (hv_exists(pad->options, "by_key", sizeof("by_key") - 1)) {
            SV** field_sv = hv_fetch(pad->options, "by_key", 6, 0);
            if (field_sv == NULL) {
                XSRETURN_UNDEF;
            }

            if (SvTYPE(*field_sv) != SVt_PV) {
                XSRETURN_UNDEF;
            }

            key_field = (char *)SvPV_nolen(*field_sv);
            if (key_field == NULL) {
                XSRETURN_UNDEF;
            }
        }
    }

    // if there is only one argument (items == 2 including $self)
    if (items == 2) {
        debug("found 1 arguments");
        if (SvIOK(ST(1))) {
            debug("first argument is IV, without payload");
        } else if (SvROK( ST(1) ) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
            debug("first argument is hashref");
        }
    } else if (items == 3) {
        debug("found 2 arguments");
        if (SvIOK(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            debug("first argument is IV and the second one is hashref");
        }
    }


    /*
    HV * node_hash = (HV*) SvRV(new_node_rv);

    debug("Found key field: %s", key_field);
    SV** key_svs = hv_fetch(node_hash, key_field, strlen(key_field), FALSE);

    if (key_svs == NULL) {
        XSRETURN_UNDEF;
    }
    
    // not an integer 
    if (!SvIOK(*key_svs)) {
        XSRETURN_UNDEF;
    }

    IV key = SvIV(*key_svs);
    debug("Key IV is %"IVdf"", key);

    // Insert the node into the node
    if (pad->root) {
        btree_insert(pad->root, key, node_hash);
    } else {
        pad->root = btree_node_create(key, node_hash);
    }
    */
    XSRETURN_YES;




void
DESTROY(self_sv)
    SV* self_sv
    PPCODE:
        BTreePad* pad = (BTreePad*) SvRV(SvRV(self_sv));
        // printf("DESTORY pad: %x\n", pad);
        // BTreePad* pad = *(BTreePad**) p;
        if (pad && pad->root) {
            Safefree(pad->root);
        }
        Safefree(pad);
        SvRV(SvRV(self_sv)) = 0;

