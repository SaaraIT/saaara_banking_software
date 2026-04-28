module ApplicationHelper
  def number_to_currency_words(amount)
    number = amount.to_i
    paise = ((amount - number) * 100).round rescue 0

    words = []
    if number >= 10**7
      words << "#{convert_to_words(number / 10**7)} crore"
      number %= 10**7
    end
    if number >= 10**5
      words << "#{convert_to_words(number / 10**5)} lakh"
      number %= 10**5
    end
    if number >= 1000
      words << "#{convert_to_words(number / 1000)} thousand"
      number %= 1000
    end
    if number >= 100
      words << "#{convert_to_words(number / 100)} hundred"
      number %= 100
    end
    words << "and #{convert_to_words(number)}" if number > 0

    rupee_part = words.join(" ").strip.capitalize 
    paise_part = paise > 0 ? " and #{convert_to_words(paise)} paise" : ""

    rupee_part + paise_part
  end

  def convert_to_words(n)
    ones = %w[zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen]
    tens = %w[zero ten twenty thirty forty fifty sixty seventy eighty ninety]

    return ones[n] if n < 20
    return tens[n / 10] if n < 100 && n % 10 == 0
    return "#{tens[n / 10]} #{ones[n % 10]}" if n < 100

    ""
  end

  def number_to_indian_currency(number, unit: "Rs. ")
    num = number.to_i.to_s
    return "#{unit}#{num}" if num.length <= 3

    # Extract last 3 digits
    last_three = num[-3, 3]
    # Remaining digits before the last 3
    remaining = num[0, num.length - 3]

    # Add commas after every 2 digits in the remaining part
    formatted = remaining.reverse.scan(/.{1,2}/).join(',').reverse

    "#{unit}#{formatted},#{last_three}"
  end


  def format_date(date_to_format)
     return "" if date_to_format.blank?
     date_to_format.to_date.strftime('%d/%m/%Y') rescue date_to_format
  end

  def display_loan_type(ltype)
    return "MORTGAGE LOAN" if ltype == "ML"
    return "SECUTRITY LOAN" if ltype == "SE"
    return "VEHICLE LOAN" if ltype == "VL"
    return "LIC/NSC" if ltype == "LICNSC"
    return "SURITY LOAN" if ltype == "SL"
    return "EDUCATION LOAN" if ltype == "EL"
    return "BUSINESS LOAN" if ltype == "BL"
    return "OTHER" if ltype == "OTHER"
    return "HOUSING LOAN" if ltype == "HOUSING LOAN"
    return "DAILY REPAYMENT LOAN" if ltype ==  "DRPL"
    return "STAFF LOAN" if ltype == "STL"
  end

  def edit_button(resource, edit_path, btn_class: "btn btn-warning", label: nil)
    resource_type = resource.class.name
    resource_id = resource.id
    label_text = label.present? ? " #{label}" : ""

    if current_user.staff?
      if EditRequest.has_approved_request?(resource_type, resource_id, current_user.id)
        link_to "Edit#{label_text}", edit_path, class: btn_class
      elsif EditRequest.has_pending_request?(resource_type, resource_id, current_user.id)
        content_tag(:span, "Edit#{label_text} Request Pending", class: "badge bg-warning text-dark")
      else
        link_to "Request Edit#{label_text}", new_edit_request_path(resource_type: resource_type, resource_id: resource_id), class: "btn btn-outline-primary"
      end
    else
      link_to "Edit#{label_text}", edit_path, class: btn_class
    end
  end

  # Alias for backward compatibility
  def loan_edit_button(loan, edit_path, btn_class: "btn btn-warning")
    edit_button(loan, edit_path, btn_class: btn_class)
  end

  # Check if current user can edit office fields (fields after office-note section)
  # Only section_head and super_admin can edit these fields
  def can_edit_office_fields?
    current_user.section_head? || current_user.super_admin?
  end

  # Check if current user can edit member fields (fields up to office-note section)
  # Only staff and manager can edit these fields
  def can_edit_member_fields?
    current_user.staff? || current_user.manager? || current_user.super_admin?
  end

  # Check if current user can edit head office fields (fields after Head Office Section)
  # Only super_admin and section_head can edit these fields
  def can_edit_head_office_fields?
    current_user.super_admin? || current_user.section_head?
  end
end
