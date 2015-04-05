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

BTreeNode * btree_find_leftmost_node(BTreeNode * n)
{
    if (n->left) {
        return btree_find_leftmost_node(n->left);
    }
    return n;
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


void btree_dump(BTreeNode* node, uint indent);

void btree_dump(BTreeNode* node, uint indent)
{
    for (int i = 0 ; i < indent; i++) {
        fprintf(stderr, "    ");
    }
    fprintf(stderr, "(o) key: %lu", node->key);
    if (node->payload) {
        fprintf(stderr, ", hash: %s", Perl_sv_peek((SV*) node->payload) );
    } else {
        fprintf(stderr, ", hash: (empty)");
    }
    fprintf(stderr, "\n");

    if (node->left) {
        for (int i = 0 ; i < indent; i++) {
            fprintf(stderr, "    ");
        }
        fprintf(stderr, "    ->left:\n");
        btree_dump(node->left, indent+2);
    }
    if (node->right) {
        for (int i = 0 ; i < indent; i++) {
            fprintf(stderr, "    ");
        }
        fprintf(stderr, "    ->right:\n");
        btree_dump(node->right, indent+2);
    }
}


IV hv_fetch_key_must(HV * hash, char *field, uint field_len);

IV hv_fetch_key_must(HV * hash, char *field, uint field_len)
{
    SV** ret = hv_fetch(hash, field, field_len, FALSE);
    if (ret == NULL) {
        croak("key field %s does not exist", field);
    }
    if (!SvIOK(*ret)) {
        croak("The value of %s is invalid", field);
    }
    return SvIV(*ret);
}




// #define ENABLE_DEBUG 1

#define debug(fmt, ...) \
            do { if (ENABLE_DEBUG) fprintf(stderr, "DEBUG: " fmt "\n", ##__VA_ARGS__); } while (0)


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

    IV key;
    HV * node_hash = NULL;

    // if there is only one argument (items == 2 including $self)
    if (items == 2) {
        debug("found 1 arguments");
        if (SvIOK(ST(1))) {
            debug("first argument is IV, without payload");
            key = SvIV( ST(1) );
            node_hash = newHV();
        } else if (SvROK( ST(1) ) && SvTYPE(SvRV(ST(1))) == SVt_PVHV ) {
            debug("first argument is hashref");
            node_hash = (HV*) SvRV(ST(1));
        }
    } else if (items == 3) {
        debug("found 2 arguments");
        if (SvIOK(ST(1)) && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV) {
            debug("first argument is IV and the second one is hashref");
            key = SvIV( ST(1) );
            node_hash = (HV*) SvRV(ST(2));
        } else {
            croak("The BTree::insert method can only accept either (key, hashref) or (hashref)");
        }
    }

    if (!key) {
        // If the key does not exist
        key = hv_fetch_key_must(node_hash, key_field, strlen(key_field));
    }

    debug("Key IV is %"IVdf"", key);
    debug("Peek: %s", Perl_sv_peek((SV*) node_hash));

    if (pad->root) {
        btree_insert(pad->root, key, node_hash);
    } else {
        pad->root = btree_node_create(key, node_hash);
    }
    btree_dump(pad->root, 0);
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

