require 'test_helper'

class PledgeControllerTest < ActionController::TestCase
  
  before do
    @user = create :user
    sign_in @user
    @patient = create :patient
    @pregnancy = create :pregnancy, patient: @patient
  end
  
  describe 'create method' do
    before do
      @pledge = create :pledge,
                pledge_type: "Sample Pledge", 
                amount: 5, 
                other_pledge_identifier: "none", 
                sent: DateTime.current, 
                sent_by: @user, 
                paid: False,
                paid_date: DateTime.current
      post :create, pregnancy_id: @pregnancy.id, pledge: @pledge, format: :js
    end

    it 'should create and save a new pledge' do
      assert_difference 'Pregnancy.find(@pregnancy).pledges.count', 1 do
        post :create, pregnancy_id: @pregnancy.id, pledge: @pledge, format: :js
      end
    end

    # it 'should respond success if the pledge submits' do
    #   assert_response :success
    # end

    # it 'should render create.js.erb if it successfully saves' do
    #   assert_template 'pledges/create'
    # end

    it 'should redirect to edit pregnancy path if it saves' do
      assert_redirected_to edit_pregnancy_path(@pregnancy)
    end

    it 'should log the creating user' do
      assert_equal Pregnancy.find(@pregnancy).pledges.last.created_by, @user
    end

  end

  describe 'update method' do
    before do
      @pledge = create :pledge, pregnancy: @pregnancy, pledge_type: 'Original Pledge'
      @pledge_edits = {pledge: {pledge_type: 'Edited Pledge'}}
      patch :update, pregnancy_id: @pregnancy, id: @pledge, pledge: @pledge_edits, format: :js
      @pledge.reload
    end

    it 'should render the correct template' do
      assert_template 'pledges/update'
    end

    it 'should respond with success' do
      assert_response :success
    end

    it 'should update the pledge_type field' do
      assert_equal @pledge.pledge_type, 'Edited Pledge'
    end

    it 'should have an audit trail' do
      assert_equal @pledge.history_tracks.count, 2
      @changes = @pledge.history_tracks.last
      assert_equal @changes.modified[:updated_by_id], @user.id
      assert_equal @changes.modified[:pledge_type], 'Edited Pledge'
    end

    it 'should refuse to save pledge type to blank' do
      [nil, ''].each do |bad_text|
        assert_no_difference 'Pregnancy.find(@pregnancy).pledges.find(@pledge).history_tracks.count' do
          @pledge_edits[:pledge_type] = bad_text
          patch :update, pregnancy_id: @pregnancy, id: @pledge, pledge: @pledge_edits, format: :js
          assert_response :bad_request
          @pledge.reload
          assert_equal @pledge.pledge_type, 'Edited Pledge'
        end
      end
    end
  end

end
