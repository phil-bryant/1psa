package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"errors"
	"unsafe"

	"1psa/onepsa"
)

//export OnepsaStringFree
func OnepsaStringFree(p *C.char) {
	if p != nil {
		C.free(unsafe.Pointer(p))
	}
}

//export OnepsaListAll
func OnepsaListAll(errOut **C.char) *C.char {
	return runWithErrOut(errOut, func() (string, error) {
		client, err := onepsa.CreateClient()
		if err != nil {
			return "", err
		}
		return onepsa.ListAllCredentialsText(client)
	})
}

//export OnepsaListFields
func OnepsaListFields(item *C.char, errOut **C.char) *C.char {
	if item == nil {
		return fail(errOut, errors.New("item is required"))
	}
	return runWithErrOut(errOut, func() (string, error) {
		client, err := onepsa.CreateClient()
		if err != nil {
			return "", err
		}
		return onepsa.ListItemFieldsText(client, C.GoString(item))
	})
}

//export OnepsaGetField
func OnepsaGetField(item, field *C.char, errOut **C.char) *C.char {
	if item == nil {
		return fail(errOut, errors.New("item is required"))
	}
	if field == nil {
		return fail(errOut, errors.New("field is required"))
	}
	return runWithErrOut(errOut, func() (string, error) {
		client, err := onepsa.CreateClient()
		if err != nil {
			return "", err
		}
		return onepsa.GetFieldValueText(client, C.GoString(item), C.GoString(field))
	})
}

// OnepsaGetMulti fetches multiple field values. fields is a comma- and/or
// whitespace-separated list of field names, same as CLI -m.
//
//export OnepsaGetMulti
func OnepsaGetMulti(item, fields *C.char, errOut **C.char) *C.char {
	if item == nil {
		return fail(errOut, errors.New("item is required"))
	}
	if fields == nil {
		return fail(errOut, errors.New("fields is required"))
	}
	return runWithErrOut(errOut, func() (string, error) {
		client, err := onepsa.CreateClient()
		if err != nil {
			return "", err
		}
		// One token with commas — normalizeRequestedFields in onepsa splits
		return onepsa.GetMultiFieldText(client, C.GoString(item), []string{C.GoString(fields)})
	})
}

func fail(errOut **C.char, err error) *C.char {
	if errOut != nil {
		*errOut = C.CString(err.Error())
	}
	return nil
}

func runWithErrOut(errOut **C.char, fn func() (string, error)) *C.char {
	s, err := fn()
	if err != nil {
		if errOut != nil {
			*errOut = C.CString(err.Error())
		}
		return nil
	}
	if errOut != nil {
		*errOut = nil
	}
	return C.CString(s)
}
