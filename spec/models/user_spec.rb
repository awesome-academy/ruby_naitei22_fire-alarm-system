require "rails_helper"

RSpec.describe User, type: :model do
    describe "validations" do
        subject { build(:user, :supervisor) }

        it { is_expected.to validate_presence_of(:name) }
        it { is_expected.to validate_length_of(:name).is_at_most(50) }
        it { is_expected.to validate_presence_of(:email) }
        it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
        it { is_expected.to allow_value("user@example.com").for(:email) }
        it { is_expected.not_to allow_value("userexample.com").for(:email) }
        it { is_expected.to validate_presence_of(:role) }
        it { is_expected.to validate_presence_of(:password) }
        it { is_expected.to validate_length_of(:password).is_at_least(6) }

        context "custom validations" do
            it "adds an error if an admin has an admin_id" do
                admin_user = build(:user, :admin)
                admin_user.admin_id = create(:user, :admin).id
                admin_user.send(:admin_must_not_have_an_admin)
                expect(admin_user.errors[:admin_id]).to include(I18n.t("activerecord.errors.models.user.attributes.admin_id.cannot_be_set_for_admin"))
            end

            it "is invalid if a supervisor does not have an admin on create" do
                supervisor = build(:user, :supervisor, admin: nil)
                expect(supervisor).not_to be_valid
                expect(supervisor.errors[:admin]).to include(I18n.t("activerecord.errors.models.user.attributes.admin.must_exist_for_supervisor"))
            end
        end
    end

    describe "associations" do
        it { is_expected.to have_many(:tokens).dependent(:destroy) }
        it { is_expected.to have_many(:zones).dependent(:destroy) }
        it { is_expected.to have_many(:invitations).dependent(:destroy) }
        it { is_expected.to have_many(:supervisors).with_foreign_key('admin_id').dependent(:nullify).inverse_of(:admin) }

        it "allows an admin to not have an admin" do
            admin = build(:user, :admin, admin: nil)
            expect(admin).to be_valid
        end

        it "requires a supervisor to have an admin" do
            supervisor = build(:user, :supervisor, admin: nil)
            expect(supervisor).not_to be_valid
        end
    end

    describe "enums" do
        it { is_expected.to define_enum_for(:role).with_values(supervisor: 0, admin: 1) }
    end

    describe "scopes" do
        it ".newest orders users by creation date descending" do
            User.destroy_all
            admin = create(:user, :admin)
            oldest = create(:user, :supervisor, admin: admin, created_at: 1.day.ago)
            newest = create(:user, :supervisor, admin: admin, created_at: Time.current)
            expect(User.where(role: :supervisor).newest).to eq([newest, oldest])
        end
    end

    describe "password reset methods" do
        let(:user) { create(:user, :supervisor) }

        it "#generate_password_reset_token! sets token and timestamp" do
            expect { user.generate_password_reset_token! }
                .to change(user, :password_reset_token).from(nil)
                .and change(user, :password_reset_sent_at).from(nil)
        end

        it "#password_reset_token_valid? returns true for recent token" do
            user.generate_password_reset_token!
            expect(user.password_reset_token_valid?).to be true
        end

        it "#password_reset_token_valid? returns false for expired token" do
            user.generate_password_reset_token!
            travel_to(3.hours.from_now) do
                expect(user.password_reset_token_valid?).to be false
            end
        end

        it "#clear_password_reset_token! nils out token fields" do
            user.generate_password_reset_token!
            user.clear_password_reset_token!
            expect(user.password_reset_token).to be_nil
            expect(user.password_reset_sent_at).to be_nil
        end
    end
end
