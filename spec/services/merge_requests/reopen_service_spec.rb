require 'spec_helper'

describe MergeRequests::ReopenService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
  let(:merge_request) { create(:merge_request, assignee: user2) }
  let(:project) { merge_request.project }

  before do
    project.team << [user, :master]
    project.team << [user2, :developer]
  end

  describe :execute do
    context 'valid params' do
      let(:service) { MergeRequests::ReopenService.new(project, user, {}) }

      before do
        service.stub(:execute_hooks)

        merge_request.state = :closed
        service.execute(merge_request)
      end

      it { merge_request.should be_valid }
      it { merge_request.should be_reopened }

      it 'should execute hooks with reopen action' do
        expect(service).to have_received(:execute_hooks).
                               with(merge_request, 'reopen')
      end

      it 'should send email to user2 about reopen of merge_request' do
        email = ActionMailer::Base.deliveries.last
        email.to.first.should == user2.email
        email.subject.should include(merge_request.title)
      end

      it 'should create system note about merge_request reopen' do
        note = merge_request.notes.last
        note.note.should include 'Status changed to reopened'
      end
    end
  end
end
