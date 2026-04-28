package onepsa

import (
	"context"
	"errors"

	"github.com/1password/onepassword-sdk-go"
)

func newTestClient(vaults []onepassword.VaultOverview, vaultErr error, itemsByVault map[string][]onepassword.ItemOverview, itemListErrByVault map[string]error, fullItems map[string]onepassword.Item, itemGetErrByID map[string]error) *onepassword.Client {
	return &onepassword.Client{
		VaultsAPI: fakeVaultsAPI{
			vaults: vaults,
			err:    vaultErr,
		},
		ItemsAPI: fakeItemsAPI{
			itemsByVault:       itemsByVault,
			itemListErrByVault: itemListErrByVault,
			fullItems:          fullItems,
			itemGetErrByID:     itemGetErrByID,
		},
	}
}

type fakeVaultsAPI struct {
	vaults []onepassword.VaultOverview
	err    error
}

func (f fakeVaultsAPI) List(context.Context) ([]onepassword.VaultOverview, error) {
	if f.err != nil {
		return nil, f.err
	}
	return f.vaults, nil
}

type fakeItemsAPI struct {
	itemsByVault       map[string][]onepassword.ItemOverview
	itemListErrByVault map[string]error
	fullItems          map[string]onepassword.Item
	itemGetErrByID     map[string]error
}

func (f fakeItemsAPI) Create(context.Context, onepassword.ItemCreateParams) (onepassword.Item, error) {
	return onepassword.Item{}, errors.New("not implemented in test fake")
}

func (f fakeItemsAPI) Get(_ context.Context, _ string, itemID string) (onepassword.Item, error) {
	if err := f.itemGetErrByID[itemID]; err != nil {
		return onepassword.Item{}, err
	}
	item, ok := f.fullItems[itemID]
	if !ok {
		return onepassword.Item{}, errors.New("item not found")
	}
	return item, nil
}

func (f fakeItemsAPI) Put(context.Context, onepassword.Item) (onepassword.Item, error) {
	return onepassword.Item{}, errors.New("not implemented in test fake")
}

func (f fakeItemsAPI) Delete(context.Context, string, string) error {
	return errors.New("not implemented in test fake")
}

func (f fakeItemsAPI) Archive(context.Context, string, string) error {
	return errors.New("not implemented in test fake")
}

func (f fakeItemsAPI) List(_ context.Context, vaultID string, _ ...onepassword.ItemListFilter) ([]onepassword.ItemOverview, error) {
	if err := f.itemListErrByVault[vaultID]; err != nil {
		return nil, err
	}
	return f.itemsByVault[vaultID], nil
}

func (f fakeItemsAPI) Shares() onepassword.ItemsSharesAPI {
	return nil
}

func (f fakeItemsAPI) Files() onepassword.ItemsFilesAPI {
	return nil
}
