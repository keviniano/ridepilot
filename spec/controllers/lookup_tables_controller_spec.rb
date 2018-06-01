require 'rails_helper'

RSpec.describe LookupTablesController, type: :controller do
  login_super_admin_as_current_user

  describe "GET #index" do
    it "populates an array of lookup tables" do
      table = create(:lookup_table)
      get :index
      expect(assigns(:lookup_tables)).to eq([table])
    end

    it "renders the :index view with empty lookup tables" do 
      get :index
      expect(response).to render_template :index
    end

    it "redirects to the first lookup table with non-empty lookup tables" do 
      table = create(:lookup_table)
      get :index
      expect(response).to redirect_to(lookup_table_path(:id => table.id))
    end
  end

  describe "GET #show" do 
    before do 
      @table = create(:lookup_table)
    end
    it "assigns the requested lookup table to @lookup_table" do 
      get :show, params: {id: @table} 
      expect(assigns(:lookup_table)).to eq(@table)
    end

    it "renders the #show view" do 
      get :show, params: {id: @table} 
      expect(response).to render_template :show
    end
  end

  describe "POST #add_value" do 
    before do 
      @table = create(:lookup_table)
      post :add_value, params: {id: @table, lookup_table: {value: 'New Purpose'}}
    end
    it "assigns the added value to @item" do 
      expect(assigns(:item)).to eq(@table.find_by_value('New Purpose'))
    end
  end

  describe "PUT #edit_value" do 
    before do 
      @table = create(:lookup_table)
      existing_purpose = create(:trip_purpose, name: 'Sample Purpose')
      put :update_value, params: {id: @table, old_value: existing_purpose.name, value: 'New Purpose'}
    end
    it "assigns the updated value to @item" do 
      expect(assigns(:item)).to eq(@table.find_by_value('New Purpose'))
    end
  end

  describe "PUT #destroy_value" do 
    before do 
      @table = create(:lookup_table)
      existing_purpose = create(:trip_purpose, name: 'Sample Purpose')
      put :destroy_value, params: {id: @table, value: existing_purpose.name}
    end
  end
end
