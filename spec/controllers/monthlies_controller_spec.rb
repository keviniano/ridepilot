require "rails_helper"

RSpec.describe MonthliesController, type: :controller do
  login_admin_as_current_user

  # This should return the minimal set of attributes required to create a valid
  # Monthly. As you add validations to Monthly, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:monthly, :funding_source_id => create(:funding_source).id)
  }

  let(:invalid_attributes) {
    attributes_for(:monthly, :start_date => "")
  }

  describe "GET #index" do
    it "assigns all monthlies as @monthlies" do
      monthly = create(:monthly, :provider => @current_user.current_provider)
      get :index, params: {}
      expect(assigns(:monthlies)).to eq([monthly])
    end
  end

  describe "GET #new" do
    it "assigns a new monthly as @monthly" do
      get :new, params: {}
      expect(assigns(:monthly)).to be_a_new(Monthly)
    end
  end

  describe "GET #edit" do
    it "assigns the requested monthly as @monthly" do
      monthly = create(:monthly, :provider => @current_user.current_provider)
      get :edit, params: {:id => monthly.to_param}
      expect(assigns(:monthly)).to eq(monthly)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Monthly" do
        expect {
          post :create, params: {:monthly => valid_attributes}
        }.to change(Monthly, :count).by(1)
      end

      it "assigns a newly created monthly as @monthly" do
        post :create, params: {:monthly => valid_attributes}
        expect(assigns(:monthly)).to be_a(Monthly)
        expect(assigns(:monthly)).to be_persisted
      end

      it "redirects to the :index" do
        post :create, params: {:monthly => valid_attributes}
        expect(response).to redirect_to(monthlies_path)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved monthly as @monthly" do
        post :create, params: {:monthly => invalid_attributes}
        expect(assigns(:monthly)).to be_a_new(Monthly)
      end

      it "re-renders the 'new' template" do
        post :create, params: {:monthly => invalid_attributes}
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          :start_date => Date.today.to_s,
          :volunteer_escort_hours => 1,
          :volunteer_admin_hours => 1,
          :funding_source_id => create(:funding_source).id,
        }
      }

      it "updates the requested monthly" do
        # Note the start date represents the first of any given month
        old_date = 1.month.ago.to_date.to_s
        monthly = create(:monthly, :provider => @current_user.current_provider, :start_date => old_date)
        expect {
          put :update, params: {:id => monthly.to_param, :monthly => new_attributes}
        }.to change { monthly.reload.start_date }.from(Date.parse(old_date).beginning_of_month).to(Date.parse(new_attributes[:start_date]).beginning_of_month)
      end

      it "assigns the requested monthly as @monthly" do
        monthly = create(:monthly, :provider => @current_user.current_provider)
        put :update, params: {:id => monthly.to_param, :monthly => valid_attributes}
        expect(assigns(:monthly)).to eq(monthly)
      end

      it "redirects to the :index" do
        monthly = create(:monthly, :provider => @current_user.current_provider)
        put :update, params: {:id => monthly.to_param, :monthly => valid_attributes}
        expect(response).to redirect_to(monthlies_path)
      end
    end

    context "with invalid params" do
      it "assigns the monthly as @monthly" do
        monthly = create(:monthly, :provider => @current_user.current_provider)
        put :update, params: {:id => monthly.to_param, :monthly => invalid_attributes}
        expect(assigns(:monthly)).to eq(monthly)
      end

      it "re-renders the 'edit' template" do
        monthly = create(:monthly, :provider => @current_user.current_provider)
        put :update, params: {:id => monthly.to_param, :monthly => invalid_attributes}
        expect(response).to render_template("edit")
      end
    end
  end

end
