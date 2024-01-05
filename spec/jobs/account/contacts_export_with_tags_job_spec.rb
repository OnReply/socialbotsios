require 'rails_helper'

RSpec.describe Account::ContactsExportJob do
  subject(:job) { described_class.perform_later }

  let!(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when export_contacts' do
    before do
      create(:contact, account: account, phone_number: '+910808080818', email: 'test1@text.example')
      8.times do
        create(:contact, account: account)
      end
      create(:contact, account: account, phone_number: '+910808080808', email: 'test2@text.example')
    end

    context 'contacts with tags' do
      context 'single tag' do
        before do
          account.contacts.first.add_labels(['tag1'])
        end

        it do
          described_class.perform_now(account.id, [])

          csv_data = CSV.parse(account.contacts_export.download, headers: true)
          first_row = csv_data[0]
          last_row = csv_data[csv_data.length - 1]
          first_contact = account.contacts.first
          last_contact = account.contacts.last

          expect([first_row['labels_list'], last_row['labels_list']]).to contain_exactly(first_contact.labels_list, last_contact.labels_list)
          expect([first_row['phone_number'], last_row['phone_number']]).to contain_exactly(first_contact.phone_number, last_contact.phone_number)
        end
      end

      context 'many tags' do
        before do
          account.contacts.first.add_labels(['tag1','tag3','tag4'])
        end

        it do
          described_class.perform_now(account.id, [])

          csv_data = CSV.parse(account.contacts_export.download, headers: true)
          first_row = csv_data[0]
          last_row = csv_data[csv_data.length - 1]
          first_contact = account.contacts.first
          last_contact = account.contacts.last

          expect([first_row['labels_list'], last_row['labels_list']]).to contain_exactly(first_contact.labels_list, last_contact.labels_list)
          expect([first_row['phone_number'], last_row['phone_number']]).to contain_exactly(first_contact.phone_number, last_contact.phone_number)
        end

        it 'should filter' do
          described_class.perform_now(account.id, [], 'tag1')

          csv_data = CSV.parse(account.contacts_export.download, headers: true)
          first_row = csv_data[0]
          last_row = csv_data[csv_data.length - 1]
          first_contact = account.contacts.first
          last_contact = account.contacts.last

          expect(csv_data.length).to eq(1)
          expect([first_row['labels_list']]).to contain_exactly(first_contact.labels_list)
        end
      end
    end

    context 'conversations with tags' do
      context 'single tag' do
        before do
          4.times do
            create(:conversation, account: account, contact: account.contacts.first)
          end
          account.contacts.first.conversations.first.add_labels(['tag1'])
        end

        it do
          described_class.perform_now(account.id, [])

          csv_data = CSV.parse(account.contacts_export.download, headers: true)
          first_row = csv_data[0]
          last_row = csv_data[csv_data.length - 1]
          first_contact = account.contacts.first
          last_contact = account.contacts.last

          expect([first_row['conversations_labels_list'], last_row['conversations_labels_list']]).to contain_exactly(first_contact.conversations_labels_list, last_contact.conversations_labels_list)
          expect([first_row['phone_number'], last_row['phone_number']]).to contain_exactly(first_contact.phone_number, last_contact.phone_number)
        end
      end

      context 'many tags' do
        before do
          4.times do
            create(:conversation, account: account, contact: account.contacts.first)
          end
          account.contacts.first.conversations.first.add_labels(['tag1','tags3','tag4'])
          account.contacts.first.conversations.last.add_labels(['tag5','tags6','tag7'])
        end

        it do
          described_class.perform_now(account.id, [])

          csv_data = CSV.parse(account.contacts_export.download, headers: true)
          first_row = csv_data[0]
          last_row = csv_data[csv_data.length - 1]
          first_contact = account.contacts.first
          last_contact = account.contacts.last

          expect([first_row['labels_list'], last_row['labels_list']]).to contain_exactly(first_contact.labels_list, last_contact.labels_list)
          expect([first_row['phone_number'], last_row['phone_number']]).to contain_exactly(first_contact.phone_number, last_contact.phone_number)
        end
      end
    end
  end
end
